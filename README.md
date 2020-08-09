# freenas-iocage-rslsync
This is a simple script to automate the installation of Resilio Sync in a FreeNAS jail. It will create a jail, install the latest version of Resilio Sync, and stores its configuration and backed-up data outside the jail.  

## Status
This script will work with FreeNAS 11.3, and it should also work with TrueNAS CORE 12.0. Due to the EOL status of FreeBSD 11.2, it is unlikely to work reliably with earlier releases of FreeNAS.

## Usage
Users often have a requirement to do a selective backup of data from their mobile and notebook devices over the internet. Resilio Sync on FreeNAS addresses many of the concerns of cloud based file synchronisation services relating to file storage limits, privacy, cost and performance.

Examples of use include:
1. Backup of photos and videos from Android (4 or later) and iOS (8 or later) smartphones and tablets.
2. Backup of local folders such as Documents, Music, Pictures and Video on Linux, OS X (10.8 or later) and Windows (7 or later) laptops and desktops.

Resilio Sync is a cross-platform P2P file syncronisation tool that encrypts files during file transfer. The only file transfer requirement is local network or internet connectivity.

### Prerequisites

Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `rslsync` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, a directory `/apps/rslsync` will be created in `$POOL_PATH`.

### Installation

Download the repository to a convenient directory on your FreeNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/freenas-iocage-rslsync`. Then change into the new freenas-iocage-rslsync directory and create a file called rslsync-config with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
POOL_PATH="/mnt/tank"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway
- POOL_PATH is the path for your data pool.

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to "rslsync"
- CONFIG_PATH: Metadata for selective backups are stored in this path, defaults to $POOL_PATH/apps/rslsync/config.
- DATA_PATH: Selective backups are stored in this path, defaults to $POOL_PATH/apps/rslsync/data
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`./rslsync-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and rslsync will be installed.

### Test

To test your installation, enter your Resilio Sync jail IP address and port 8888 e.g. `10.1.1.3:8888` in a browser. If the installation was successful, you should see the Resilio Sync welcome screen.

## Support and Discussion

Questions or issues about this resource can be raised in [this forum thread](https://www.ixsystems.com/community/threads/reverse-proxy-using-caddy-with-optional-automatic-tls.75978/).  Be aware that any Caddyfile examples in that thread prior to August 2020 will be incorrect, as Caddy v1 used a significantly different Caddyfile syntax.

Though we'll try to help on that thread, once Caddy's up and running, the [Caddy forum](https://caddy.community/) is likely to be a better resource for its configuration, particularly with applications whose reverse proxy settings prove to be difficult.  Once you have something working, though, please post back in the iXSystems forum.


