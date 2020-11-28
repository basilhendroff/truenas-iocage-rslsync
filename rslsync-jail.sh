#!/bin/sh
# Build an iocage jail under FreeNAS 11.3-12.0 using the current release of Resilio Sync
# git clone https://github.com/basilhendroff/freenas-iocage-rslsync

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="rslsync"
CONFIG_NAME="rslsync-config"
CONFIG_PATH=""
DATA_PATH=""
USER_NAME="${JAIL_NAME}"
GROUP_NAME="${JAIL_NAME}"
UID_GID=817

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for rslsync-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"
INCLUDES_PATH="${SCRIPTPATH}"/includes

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by rslsync-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  POOL_PATH="/mnt/$(iocage get -p)"
  echo 'POOL_PATH defaulting to '$POOL_PATH
fi

# If DATA_PATH and CONFIG_PATH weren't set in rslsync-config, set them
if [ -z "${DATA_PATH}" ]; then
  DATA_PATH="${POOL_PATH}"/apps/rslsync/data
fi
if [ -z "${CONFIG_PATH}" ]; then
  CONFIG_PATH="${POOL_PATH}"/apps/rslsync/config
fi

# Sanity check DATA_PATH and CONFIG_PATH -- they have to be different and can't be the same as POOL_PATH
if [ "${CONFIG_PATH}" = "${DATA_PATH}" ]
then
  echo "CONFIG_PATH and DATA_PATH must be different!"
  exit 1
fi
if [ "${DATA_PATH}" = "${POOL_PATH}" ] || [ "${CONFIG_PATH}" = "${POOL_PATH}" ]
then
  echo "DATA_PATH and CONFIG_PATH must all be different from POOL_PATH!"
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####
#
# Jail Creation
#
#####

# List packages to be auto-installed after jail creation
cat <<__EOF__ >/tmp/pkg.json
	{
  "pkgs":[
  "nano","bash","ca_root_nss"
  ]
}
__EOF__

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
#if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" boot="on" host_hostname="${JAIL_NAME}" dhcp="on"
then
	echo "Failed to create jail"
	exit 1
fi
rm /tmp/pkg.json

#####
#
# Directory Creation and Mounting
#
#####

mkdir -p "${CONFIG_PATH}"
mkdir -p "${DATA_PATH}"
chown -R 817:817 "${CONFIG_PATH}" "${DATA_PATH}"

JAIL_TMP_INCLUDE="/tmp/includes"
JAIL_VAR_DB="/var/db/rslsync"
USR_LOCAL="/usr/local"

iocage exec "${JAIL_NAME}" mkdir -p "${JAIL_TMP_INCLUDE}" 
iocage exec "${JAIL_NAME}" mkdir -p "${JAIL_VAR_DB}"
iocage exec "${JAIL_NAME}" mkdir -p "${USR_LOCAL}/etc/rc.d"
iocage exec "${JAIL_NAME}" mkdir -p "${USR_LOCAL}/bin"

iocage exec "${JAIL_NAME}" "pw user add ${USER_NAME} -c ${GROUP_NAME} -u ${UID_GID} -d /nonexistent -s /usr/bin/nologin"

iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" "${JAIL_TMP_INCLUDE}" nullfs rw 0 0
iocage fstab -a "${JAIL_NAME}" "${CONFIG_PATH}" "${JAIL_VAR_DB}" nullfs rw 0 0
iocage fstab -a "${JAIL_NAME}" "${DATA_PATH}" /media nullfs rw 0 0

#####
#
# Rslsync Download and Setup
#
#####

FILE="resilio-sync_freebsd_x64.tar.gz"
RESILIO_CDN="https://download-cdn.resilio.com/stable/FreeBSD-x64"
if ! iocage exec "${JAIL_NAME}" fetch -o /tmp "${RESILIO_CDN}/${FILE}"
then
	echo "Failed to download Resilio/Sync"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" tar xzf /tmp/"${FILE}" -C "${USR_LOCAL}/bin/"
then
	echo "Failed to extract Resilio/Sync"
	exit 1
fi
iocage exec "${JAIL_NAME}" rm /tmp/"${FILE}"

# Copy pre-written config files
iocage exec "${JAIL_NAME}" cp "${JAIL_TMP_INCLUDE}/rslsync" "${USR_LOCAL}/etc/rc.d/"
iocage exec "${JAIL_NAME}" cp "${JAIL_TMP_INCLUDE}/rslsync.conf.sample" "${USR_LOCAL}/etc/"
iocage exec "${JAIL_NAME}" cp "${JAIL_TMP_INCLUDE}/rslsync.conf.sample" "${USR_LOCAL}/etc/rslsync.conf"

iocage exec "${JAIL_NAME}" sysrc rslsync_enable="YES"

iocage restart "${JAIL_NAME}"

# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" "${JAIL_TMP_INCLUDE}" nullfs rw 0 0
iocage exec "${JAIL_NAME}" rmdir "${JAIL_TMP_INCLUDE}"
