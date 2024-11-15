#!/bin/bash gg
# Flags for controlling if the monitor is currently enabled, 
# if opcmsg notifications are sent to Operation Manager and if mails are sent
OPCMSG_ENABLED='0'
MAIL_ENABLED='1'
VISUALISATION_ENABLED='0'
DEBUG='1'
TRACE='0'
MAX_VERBOSITY='0'
STDOUT='1' # print output to stdout
enable='1'

# List scripts, that should be run
RUNNERS="cron_docbroker_memory_heal.sh"
# Name of user that will be running the scripts
SUDO_USER='dmadmin'
# Name of stage (required for loading proper config files)
STAGE='DEV'

# Other required variables
_DAY=$(date +%F)
SCRIPT_ROOT=$(dirname $(readlink -f $0))
DOCUMENTUM='/vg01lv01'
_DOCBROKER_LIST=""
_APPLICATION='Documentum'
_SEVERITY="warning"
_OBJECT="docbroker_memory_check"
_MEMORY_THRESHOLD=1024000 # in KiloBytes

# Load environment-specific variables
source "$SCRIPT_ROOT/settings/settings_$STAGE.sh"
#override SCRIPT_ROOT
SCRIPT_ROOT=$(dirname $(readlink -f $0))

# Load environment settings
if [ -f "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh" ]; then
    source "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
    echo "loaded host specific configuration: $SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
fi

# Load modules necessary for all scripts
source $SCRIPT_ROOT/modules/notificationHandler.sh
source $SCRIPT_ROOT/modules/outputHandler.sh
source $SCRIPT_ROOT/modules/itemStateHandler.sh
source $SCRIPT_ROOT/modules/inputParameterHandler.sh

# Create logs directory if it doesnt exist
if [[ ! -d "$SCRIPT_ROOT/logs/" ]]
then
        mkdir -p "$SCRIPT_ROOT/logs/"
        touch "$SCRIPT_ROOT/logs/crontab.log" 
        chown -R $SUDO_USER:$SUDO_USER "$SCRIPT_ROOT/logs/"
        chmod -R +rw "$(dirname $(readlink -f $0))/logs/"
fi

if [[ ! -f "$SCRIPT_ROOT/logs/monitoring.log.$_DAY" ]]
then
        touch "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
        chown -R $SUDO_USER:$SUDO_USER "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
        chmod +rw "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
fi

# Execute the scripts, send the notification if a script is already running
for _RUNNER_NAME in $RUNNERS; do
        if pgrep "${_RUNNER_NAME%.*}">/dev/null 2>&1
          then
                echo "$_RUNNER_NAME is already running"
                source "$SCRIPT_ROOT/settings/settings_$STAGE.sh"

                _TIMESTAMP=`date +"%Y-%m-%d %T"`
                _MAIL_BODY="$_TIMESTAMP $HOSTNAME $STAGE docbroker restart script tried to start before previous instance was completed - $_RUNNER_NAME"
                mailx -v -r "$_MAIL_SENDER" -s "[HP OVO] $STAGE $HOSTNAME WARNING docbroker restart script did not start" -S smtp="$SMTP_SERVER" $MAIL_RECEIPIENT <<< $_MAIL_BODY
                unset _TIMESTAMP _MAIL_BODY MAIL_SENDER MAIL_RECEIPIENT SMTP_SERVER HOSTNAME STAGE
                exit 1
          else
                # Find all ini files with docbroker configuration
                _DOCBROKERS=(${_DOCBROKERS:-`find $DOCUMENTUM/dba/ -type f -name "docbroker*.ini"`})
                if [ $TRACE == 1 ]; then outputHandler "_DOCBROKERS[*]: '${_DOCBROKERS[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                for ini_file in "${_DOCBROKERS[@]}";
                do
                        outputHandler "Running test for $ini_file" "DEBUG" "$_APPLICATION" "$_OBJECT" 
	                # Get docbroker info: PID, port, ini file
                        _PROC_INFO=(${_PROC_INFO:-`ps -ef | grep dmdocbroker| grep $ini_file | grep -iv grep | awk '{print $2} {print $10} {print $12}'`})
                        if [ $TRACE == 1 ]; then outputHandler "_PROC_INFO[*]: '${_PROC_INFO[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                        if [ ! -z "$_PROC_INFO" ]; then
                                # Get current memory usage for docbroker
                                _MEM_USAGE=${_MEM_USAGE:-`pmap -x ${_PROC_INFO[0]} | tail -n 1 | awk '{print $3}'`}
                                if [ $DEBUG == 1 ]; then outputHandler "Current memory usage for $ini_file: '${_MEM_USAGE}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                                if [ $_MEMORY_THRESHOLD -lt $_MEM_USAGE ];
                                then
                                        outputHandler "Current memory usage for $ini_file exceeds $_MEMORY_THRESHOLD KB: ${_MEM_USAGE} - attempting to stop docbroker" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
                                        # Get name of docbroker stop script
                                        _STOP_SCRIPT_NAME=${_STOP_SCRIPT_NAME:-`grep -l "${_PROC_INFO[1]}" $DOCUMENTUM/dba/dm_stop_docbroker* | xargs -L 1 basename | uniq | grep -v bak`}
                                        if [ $TRACE == 1 ]; then outputHandler "_STOP_SCRIPT_NAME: '${_STOP_SCRIPT_NAME}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                                        # Get name of docbroker service
                                        _SERVICE_NAME=${_SERVICE_NAME:-`grep -l "${_STOP_SCRIPT_NAME}\b" /usr/lib/systemd/system/documentum.docbroker* | xargs -L 1 basename`}
                                        if [ $TRACE == 1 ]; then outputHandler "_SERVICE_NAME: '${_STOP_SCRIPT_NAME}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                                        # Stop the docbroker
                                        outputHandler "Stopping docbroker using $DOCUMENTUM/dba/$_STOP_SCRIPT_NAME" "DEBUG" "$_APPLICATION" "$_OBJECT" 
                                        /usr/bin/sudo -i -u dmadmin "$DOCUMENTUM/dba/$_STOP_SCRIPT_NAME"
                                        sleep 10
                                        # Start the docbroker service
                                        outputHandler "Starting $_SERVICE_NAME docbroker service " "DEBUG" "$_APPLICATION" "$_OBJECT" 
                                        systemctl start $_SERVICE_NAME
                                        _DOCBROKER_LIST="${_DOCBROKER_LIST} $_SERVICE_NAME"
                                fi
                        fi
                        unset _PROC_INFO _MEM_USAGE _SERVICE_NAME _STOP_SCRIPT_NAME
                done
        	unset _DOCBROKERS
                if [ ! -z "${_DOCBROKER_LIST[*]}" ]; then
                        _MSG="Error: docbroker was restarted due to exceeding memory threshold - ${_DOCBROKER_LIST[*]}"
                        notificationHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
                        unset _MSG
                fi        
        fi
done
unset _RUNNER_NAME RUNNERS SUDO_USER STAGE _DAY SCRIPT_ROOT DOCUMENTUM  _DOCBROKER_LIST _APPLICATION _APPLICATION _SEVERITY _OBJECT _MEMORY_THRESHOLD

