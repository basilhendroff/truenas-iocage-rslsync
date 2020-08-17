# freenas-iocage-rslsync
This is a simple script to automate the installation of Resilio Sync in a FreeNAS jail. It will create a jail, install the latest version of Resilio Sync (x64) for FreeBSD from [resilio.com](https://www.resilio.com/individuals/), and store its configuration and client backup data outside the jail.  

## Status
This script will work with FreeNAS 11.3, and it should also work with TrueNAS CORE 12.0. Due to the EOL status of FreeBSD 11.2, it is unlikely to work reliably with earlier releases of FreeNAS.

## Usage
Users often use cloud-based services (such as Google Drive, Microsoft OneDrive, Apple iCloud and DropBox just to name a few), to do selective backups of data from their mobile and notebook devices over the internet. The appeal of Resilio Sync on FreeNAS is that it addresses many of the concerns of cloud based file synchronisation services relating to file storage limits, photo and video compression, privacy, cost and performance.

### Prerequisites

Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `rslsync` on your main storage pool and nested sub-datasets `config` and `data`.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If these datasets are not present, directories `/apps/rslsync/config` and `/apps/rslsync/data` will be created in `$POOL_PATH`.

### Installation

Download the repository to a convenient directory on your FreeNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/freenas-iocage-rslsync`. Then change into the new freenas-iocage-rslsync directory and create a file called rslsync-config with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to `rslsync`.
- POOL_PATH: The path for your data pool. It is set automatically if left blank.
- CONFIG_PATH: Client configuration data is stored in this path; defaults to `$POOL_PATH/apps/rslsync/config`.
- DATA_PATH: Selective backups are stored in this path; defaults to `$POOL_PATH/apps/rslsync/data`.
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`./rslsync-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and rslsync will be installed.

### Test

To test your installation, enter your Resilio Sync jail IP address and port 8888 e.g. `10.1.1.3:8888` in a browser. If the installation was successful, you should see a Resilio Sync configuration screen.

### Initial Configuration

`$DATA_PATH` is mounted inside the jail at `/media`. Your backups go there. When configuring the application, point the `Default folder location` and `File download location` to `/media` in the preference settings.

## Support and Discussion

Useful sources of support include the [Sync Help Centre](https://help.resilio.com/hc/en-us/categories/200140177-Get-started-with-Sync) and [Sync Forum](https://forum.resilio.com/)

Questions or issues about this resource can be raised in [this forum thread](https://www.ixsystems.com/community/threads/scripted-resilio-sync-installation.86766/).  


