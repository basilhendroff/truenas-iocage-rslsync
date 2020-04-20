#!/bin/sh
# Build an iocage jail under FreeNAS 11.3 using the current release of Resilio Sync
# https://github.com/basilhendroff/freenas-iocage-rslsync

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
JAIL_NAME="rslsync"
JAIL_IP=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
RELEASE="11.3-RELEASE"
JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)

POOL_PATH=""
TIME_ZONE=""
HOST_NAME=""
DATABASE="mariadb"
DB_PATH=""
FILES_PATH=""
PORTS_PATH=""
CONFIG_PATH=""
DL_FLAGS=""
DNS_SETTING=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
. "${SCRIPTPATH}"/rslsync-config
INCLUDES_PATH="${SCRIPTPATH}"/includes

# Check for rslsync-config and set configuration
if ! [ -e "${SCRIPTPATH}"/rslsync-config ]; then
  echo "${SCRIPTPATH}/rslsync-config must exist."
  exit 1
fi

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by nextcloud-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
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
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
	echo "Failed to create jail"
	exit 1
fi
rm /tmp/pkg.json
