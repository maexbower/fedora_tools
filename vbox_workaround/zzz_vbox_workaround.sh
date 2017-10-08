#!/bin/bash
#script has to be run with admin rights
echo "Virtual Box Kernel Modules Workaround Script started"
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SCRIPT_VERSION=2
SYSTEMD_TEMPLATE_NAME="vbox_kmod_workaround.service.template"
INSTALLSCRIPT_NAME="vbox_workaround.sh"
SYSTEMD_NAME="vbox_workaround.service"
STD_INSTALL_PATH="/usr/local/bin/"
STD_SYSTEMD_PATH="/etc/systemd/system/"
SCRIPT_MODE="HELP"
INSTALL_PATH="${STD_INSTALL_PATH}"
STD_INSTALL_TYPE="SYSTEMD"
INSTALL_TYPE=""
STD_REMOVE_TYPE="ALL"
REMOVE_TYPE=""
SYSTEMD_PATH="${STD_SYSTEMD_PATH}"

function printHelp
{
	echo "Virtual Box Kernel Modules Work Around Script"
	echo "USAGE:"
        echo "-a|--auto: no interaction. Nothing will be prompted or installed."
        echo "-i|--install <CRON|SYSTEMD>: Don't run just install service/cron. If systemd is available this is prefered"
        echo "-r|--remove <CRON|SYSTEMD>: Don't run just remove service/cron. If empty both will be removed"
        echo "-p|--path </path/to/install/>: specify install path for script. Default is ${STD_INSTALL_PATH}"
}

function installScriptFile
{
	if [ -f "${INSTALL_PATH}${INSTALLSCRIPT_NAME}" ]; then
                echo "Script file exists. Check Version..."
		installed_version=$(grep -E "^(SCRIPT_VERSION=)(.*)$" "${INSTALL_PATH}${INSTALLSCRIPT_NAME}")
		if [[ "${installed_version##SCRIPT_VERSION=}" -lt "$SCRIPT_VERSION" ]]; then
			echo "This is a newer version. Start Copy."
			cp -f "$0" "${INSTALL_PATH}${INSTALLSCRIPT_NAME}"
		else
			echo "No update available"
		fi
        else
                echo "Copy Script file to ${INSTALL_PATH}${INSTALLSCRIPT_NAME}"
                cp -f "$0" "${INSTALL_PATH}${INSTALLSCRIPT_NAME}"
        fi
	echo "make the script executable"
        chmod +x "${INSTALL_PATH}${INSTALLSCRIPT_NAME}"
	if [ -f "${INSTALL_PATH}${INSTALLSCRIPT_NAME}" ]; then
		echo "scriptfile deployed successfully"
		return 0
	else
		echo "scriptfile was not deployed. Abort"
		return 1
	fi
}

function installCron
{
	CRONLINE="@reboot ${INSTALL_PATH}${INSTALLSCRIPT_NAME} -a"
	echo "search for existing cron job"
	while true; do
		possible_match=$(crontab -l |grep -m 1 "${INSTALLSCRIPT_NAME}")
		if [[ "[$possible_match]" != "[]" ]]; then
			echo "cronjob may be installed. Please check this line"
			echo $possible_match
			echo "Want to remove it?"
			read -p "yes/no: " remove
			if [[ "$remove" == "yes" ]]; then
				echo "removing line"
				crontab -l | { cat| grep -v "^$possible_match$"; } | crontab -
			else
				echo "keeping line in cronlist"
			fi
		else
			break
		fi
	done
	echo "activate cron job"
	crontab -l | { cat; echo "$CRONLINE"; } | crontab -
	possible_match=$(crontab -l |grep "^$CRONLINE$")
        if [[ "[$possible_match]" != "[]" ]]; then
		echo "cronjob installed successfully"
		return 0
	else
		echo "something went wrong while adding script to cronlist"
		return 1
	fi
}

function installSystemd
{
	echo "install systemd service"
	#check if template file exists
	if [[ -f "./${SYSTEMD_TEMPLATE_NAME}" ]]; then
		echo "Copy sytemd service file template to location"
		cp -f "./${SYSTEMD_TEMPLATE_NAME}" "${SYSTEMD_PATH}${SYSTEMD_NAME}"
		if [[ -f "${SYSTEMD_PATH}${SYSTEMD_NAME}" ]]; then
			full_install_path=${INSTALL_PATH//\//\\\/}${INSTALLSCRIPT_NAME}
			sed -i "s/\!PathToScript\!/${full_install_path}/" "${SYSTEMD_PATH}${SYSTEMD_NAME}"
			echo "copy successfully. Enable service"
			systemctl daemon-reload
			systemctl enable "${SYSTEMD_NAME}"
		else
			echo "failed to copy systemd template. Abort"
			return 1
		fi
	else
		echo "systemd temlate file missing. Abort."
		return 1
	fi
	return 0
}

function removeCron
{
	CRONLINE="@reboot ${INSTALL_PATH}${INSTALLSCRIPT_NAME} -a"
	possible_match=$(crontab -l |grep "^$CRONLINE$")
        if [[ "[$possible_match]" == "[]" ]]; then
                echo "cronjob seems not installed. Try extended search."
		while true; do
          		possible_match=$(crontab -l |grep -m 1 "${INSTALLSCRIPT_NAME}")
        		if [[ "[$possible_match]" != "[]" ]]; then
                		echo "cronjob may be installed. Please check this line"
                		echo $possible_match
                		echo "Want to remove it?"
                		read -p "yes/no:" remove
                		if [[ "$remove" == "yes" ]]; then
                        		echo "removing line"
                        		crontab -l | { cat| grep -v "^$possible_match$"; } | crontab -
                		else
        	                	echo "keeping line in cronlist"
        	        	fi
			else
				echo "search has returned something"
				break
			fi
		done
	fi
	echo "removing cronjob"
	crontab -l | { cat| grep -v "^$CRONLINE$"; } | crontab -
	possible_match=$(crontab -l |grep "^$CRONLINE$")
        if [[ "[$possible_match]" == "[]" ]]; then
                echo "cronjob removed successfully"
        else
                echo "something went wrong while removing script from cronlist"
        fi
}

function removeSystemd
{
	echo "removing systemd service"
	if [[ -f "${SYSTEMD_PATH}${SYSTEMD_NAME}" ]]; then
		echo "diable service"
		systemctl disable "${SYSTEMD_NAME}"
		echo "remove service file"
		rm -f "${SYSTEMD_PATH}${SYSTEMD_NAME}"
		systemctl daemon-reload
	else
		echo "service file does not exist. Is service really installed? Aborting."
		return 1
	fi
	if [[ -f "${SYSTEMD_PATH}${SYSTEMD_NAME}" ]]; then 
		echo "deleting of service failed."
		return 1
	else
		echo "deleting of service successfully"
		return 0
	fi
}

function removeScriptFile
{
	echo "removing script file ${INSTALL_PATH}${INSTALLSCRIPT_NAME} "
	if [[ -f "${INSTALL_PATH}${INSTALLSCRIPT_NAME}" ]]; then
		rm -f "${INSTALL_PATH}${INSTALLSCRIPT_NAME}"
	else
		echo "Script file does not exist. Was it installed previously? Aborting."
		return 1
	fi
	if [[ -f "${INSTALL_PATH}${INSTALLSCRIPT_NAME}" ]]; then
		echo "deleting of scriptfile failed."
                return 1
        else
                echo "deleting of scriptfile successfully"
                return 0
        fi
}

function installScript
{
	installScriptFile
	if [[ $? == 1 ]]; then
		return 1
	fi

	case ${INSTALL_TYPE} in
		SYSTEMD)
			echo "install type = systemd"
			installSystemd
			;;
		CRON)
			echo "install type = cron"
			installCron
			;;
		*)
			echo "no valid install type ${INSTALL_TYPE}"
			;;
	esac
}

function removeScript
{
	echo "WARNING: If you have installed both systems you have to check that the other one is not pointing on the currently deleted file!"
	removeScriptFile
	#if [[ $? == 1 ]]; then
                #return 1
		#if file missing cleanup
        #fi

	case ${REMOVE_TYPE} in
                SYSTEMD)
                        echo "remove type = systemd"
                        removeSystemd
                        ;;
                CRON)
                        echo "remove type = cron"
                        removeCron
                        ;;
		*)
			echo "removing all type"
			removeSystemd
			removeCron
			;;
        esac
}

function runTheMagic
{
	echo "testing if modules load error came up on boot"
	#run dracut again to add vbox modules
	moduleerr=$(/usr/bin/journalctl -b |grep ".*systemd-modules-load.*Failed to find module.*vbox.*")
	#echo $moduleerr
	if [ "$moduleerr" ]; then
		echo "error found. Running dracut..."
        	dracut -v -f
	else
		echo "no error found. Everything seems to be fine."
	fi
}

#check parameters
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
    		-a|--auto)
    			SCRIPT_MODE="RUN"
    			#shift # past argument
    			;;
		-i|--install)
			echo "detected install param"
			SCRIPT_MODE="INSTALL"
			if [[ ${2:0:1} == "-" ]] || [[ "[$2]" == "[]" ]]; then
				INSTALL_TYPE="${STD_INSTALL_TYPE}"
			else
				INSTALL_TYPE="$2"
				shift
			fi
			echo "install type set to ${INSTALL_TYPE}"
			;;
		-r|--remove)
			echo "detected remove param"
			SCRIPT_MODE="REMOVE"
			if [[ ${2:0:1} == "-" ]] || [[ -z "$2" ]]; then
                                REMOVE_TYPE="${STD_REMOVE_TYPE}"
                        else
                                REMOVE_TYPE="$2"
				shift
                        fi
			echo "remove type set to ${REMOVE_TYPE}"
			;;
    		-p|--path)
			echo "detected path param"
    			INSTALL_PATH="$2"
			echo "install path set to ${INSTALL_PATH}"
    			shift
			;;
    		*)
			echo "param $key not known"
			SCRIPT_MODE="HELP"
    			;;
	esac
	shift # past argument or value
done

case ${SCRIPT_MODE} in
	HELP)
		printHelp
		;;
	INSTALL)
		installScript
		;;
	REMOVE)
		removeScript
		;;
	RUN)
		runTheMagic
		;;
esac
echo "Script finished"
