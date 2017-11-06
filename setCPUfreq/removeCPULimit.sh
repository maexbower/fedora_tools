#!/bin/bash
cpupower frequency-set -u 3.4GHz
CURRENT_FREQ=$(/usr/bin/cpupower frequency-info| grep 'current CPU frequency: [0-9]\.[0-9][0-9] GHz' | grep -o '[0-9]\.[0-9][0-9]')
kdialog --msgbox "Current CPU Limit: ${CURRENT_FREQ} GHz"
