# vbox_workaround
on every kernelupdate the virtual box drivers are missing in the boot image. Boot log will show an error on systemd-modules-load.service on every boot. After logging in this service shows everything working fine.
To fix this automatically I created this script that installs as cron and looks in the journal of the boot if there are any vbox module errors. If true it will run dracut again and insert the modules into the boot image.
## Install
  `git clone`

  `chmod +x zzz_vbox_workaround.sh`

  `./zzz_vbox_workaround.sh -i`

## Usage
   `sudo vbox_workaround.sh [-i|--install] | [-r|--remove] | [-a|--auto] | [-p|--path </path/to/install/folder/] | [help]`

   >`-i|--install <CRON|SYSTEMD>: Don't run just install service/cron. If systemd is available this is prefered
   >
   >`-i|--install <CRON|SYSTEMD>: Don't run just install service/cron. If systemd is available this is prefered
   >
   >`a|--auto: no interaction. Nothing will be prompted or installed.
   >
   >`-p|--path </path/to/install/>: specify install path for script. Default is /usr/local/bin
   >
   >`[help]`: show usage.

## Note
It can use cron and systemd. It will use systemd by default.

## Examples
`sudo ./zzz_vbox_workaround.sh -i SYSTEMD -p /usr/bin/`
This will copy the script into the dir /usr/bin and copy the service template to /etc/systemd/system and enable the service

`sudo ./zzz_vbox_workaround.sh -r`
This will remove the script file from the standard dir (/usr/local/bin/) and remove the systemd service AND the cron entry

`sudo ./zzz_vbox_workaround.sh -r SYSTEMD -p /usr/bin/`
This will remove the systemd service and the script file that was set up in the first example
