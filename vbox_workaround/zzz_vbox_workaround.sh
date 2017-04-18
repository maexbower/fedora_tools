#!/bin/bash
#script has to be run with admin rights
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
INSTALLPATH="/usr/local/bin/vbox_workaround.sh"
CRONLINE="@reboot $INSTALLPATH -a"
SYSTEMDNAME="vbox_workaround.service"
NOTINTERACTIVE=""
function setcronjob
{
	if [ -f "$INSTALLPATH" ]; then
		echo "file exists"
	else
		echo "Copy Script file to $INSTALLPATH"
		cp $0 $INSTALLPATH
	fi
	chmod +x $INSTALLPATH
	crontab -l | { cat; echo "$CRONLINE"; } | crontab -
}
function setsystemd
{
	echo "systemd not implemented yet"
}
function removecronjob
{
	rm $INSTALLPATH
	crontab -l | { cat| grep -v "^$CRONLINE$"; } | crontab -
}
function removesystemd
{
	echo "systemd not implemented yet"
}
function installscript
{
	#check if crontab is available or if we need to use a systemd service
	cronstatus=$(systemctl status crond.service |grep "Active: active (running)")
	if [ "$cronstatus" ]; then
        	currentcrons=$(crontab -l |grep "$CRONLINE")
        	if [ -z "$currentcrons" ]; then
               	 	echo "No Cron Job for this workaround active. Should we enable it at reboot time?"
                       	read -p "(yes/no):" INSTALLCRON
			if [ "$INSTALLCRON" == "yes" ]; then
       	                        echo "install cronjob..."
                                setcronjob
                       	else
               	                echo "no cronjob will be installed"
       	                fi
	        else
                	echo "Cronjob ist bereits eingerichtet"
        	fi
	else
        	echo "No Cron available. Should we try to create a systemd job instead?"
		read -p "(yes/no):" INSTALLSYSTEMD
		if [ "$INSTALLCRON" == "yes" ]; then
			systemdstatus=$(systemctl status $SYSTEMDNAME |grep "Active:")
        		if [ "$systemdstatus" ]; then
               	 		echo "Systemd Service existiert bereits"
       	 		else
        	        	echo "Kein Systemd Service vorhanden. Installiere."
				setsystemd
	        	fi
		else
			echo "User said no!"
		fi

	fi

}
function removescript
{
        #check if crontab is available or if we need to use a systemd service
        cronstatus=$(systemctl status crond.service |grep "Active: active (running)")
        if [ "$cronstatus" ]; then
                currentcrons=$(crontab -l |grep "$CRONLINE")
                if [ -z "$currentcrons" ]; then
                        echo "No Cron Job for this workaround active. Nothing to remove."
                else
                        echo "Cronjob wird entfernt."
			removecronjob
                fi
        fi
	systemdstatus=$(systemctl status $SYSTEMDNAME |grep "Active:")
	if [ "$systemdstatus" ]; then
		echo "Systemd Service wird gelöscht"
		removesystemd
	else
		echo "Kein Systemd Service vorhanden"
	fi
}
#check parameters
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
    		-a|--auto)
    			NOTINTERACTIVE="TRUE"
    			#shift # past argument
    			;;
		-i|--install)
			echo "Install Script"
			installscript
			exit 0
			;;
		-r|--remove)
			echo "Remove Script"
			removescript
			exit 0
			;;
    		#-s|--searchpath)
    		#	SEARCHPATH="$2"
    		#	shift # past argument
    		#	;;
    		#-l|--lib)
    		#	LIBPATH="$2"
    		#	shift # past argument
    		#	;;
    		#--default)
    		#	DEFAULT=YES
    		#	;;
    		*)
			echo "USAGE:"
			echo "-a|--auto: no interaction. Nothing will be prompted or installed."
			echo "-i|--install: Don't run just install service/cron"
			echo "-r|--remove: Don't run just remove service/cron"
            		# unknown option
    			;;
	esac
	shift # past argument or value
done

if [ -z "$NOTINTERACTIVE" ]; then
	installscript
fi

#run dracut again to add vbox modules
moduleerr=$(/usr/bin/journalctl -b |grep ".*systemd-modules-load.*Failed to find module.*vbox.*")
#echo $moduleerr
if [ "$moduleerr" ]; then
	dracut -v -f
fi
