# vbox_workaround
on every kernelupdate the virtual box drivers are missing in the boot image. Boot log will show an error on systemd-modules-load.service on every boot. After logging in this service shows everything working fine.
To fix this automatically I created this script that installs as cron and looks in the journal of the boot if there are any vbox module errors. If true it will run dracut again and insert the modules into the boot image.
##Install
git clone
chmod +x zzz_vbox_workaround.sh
./zzz_vbox_workaround.sh -i
##Usage
sudo vbox_workaround.sh [-i|--install] | [-r|--remove] | [-a|--auto] | [help]
 [-i|--install]: doesn't run. Just install Cron job.
 [-r|--remove]: doesn't run. Just remove Cron Job.
 [-a|--auto]: just run. Do not prompt or install anything
 [help]: show usage.
##Note
systemd service usage is not implemented yet.
