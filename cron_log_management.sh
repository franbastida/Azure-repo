#!/bin/bash
# Flags for controlling if the monitor is currently enabled,
enable='1'

# Name of user that will be running the scripts
SUDO_USER='dmadmin'

# Other required variables
SCRIPT_ROOT=$(dirname $(readlink -f $0))
_RETENCY=90 # Delete files older than $_RETENCY days

_LOG_FILES=(${_LOG_FILES:-`find $SCRIPT_ROOT/logs/ -type f ! -name "*tar.gz"  -name "*.log.*" -daystart -mtime +0`})
for _file in "${_LOG_FILES[@]}";
do
        echo "Packing ${_file##*/}" >> $SCRIPT_ROOT/logs/log_management.log
        _SET_DATE=`date -r $SCRIPT_ROOT/logs/${_file##*/} "+%y%m%d%H%M"`
        tar -C $SCRIPT_ROOT/logs/ -czf $SCRIPT_ROOT/logs/${_file##*/}.tar.gz ${_file##*/} --remove-files
        chown $SUDO_USER:$SUDO_USER $SCRIPT_ROOT/logs/${_file##*/}.tar.gz
        touch -a -m -t $_SET_DATE $SCRIPT_ROOT/logs/${_file##*/}.tar.gz
done

_TAR_FILES=(${_TAR_FILES:-`find $SCRIPT_ROOT/logs/ -type f -name "*.tar.gz" -daystart -mtime +${_RETENCY}`})
for _file in "${_TAR_FILES[@]}";
do
        _DATE_FROM_FILE=(${_file//./ })
        let _DIFF=($(date +%s)-$(date +%s -d ${_DATE_FROM_FILE[2]}))/86400
        if [ $_RETENCY -lt $_DIFF ]; then
                echo "Removing $_file because it is older ($_DIFF days) than ${_RETENCY}" >> $SCRIPT_ROOT/logs/log_management.log
                rm -f $_file
        fi
        unset _DATE_FROM_FILE _DIFF
done

unset _LOG_FILES _TAR_FILES SCRIPT_ROOT

