#!/bin/bash bastida1
# Flags for controlling if the monitor is currently enabled,
enable='1'

# Check if the monitoring is enabled
if [ $enable == 0 ]
    then
        exit
fi

#Configuration variables
_DAY=$(date +%F)
SCRIPT_ROOT=$(dirname $(readlink -f $0))
STAGE='DEV'

# List runners
# Tomcat
#       test_tomcat.sh --> tomcatCountProcess
#       test_brava_mp.sh --> bravaMountPointTester

RUNNERS="test_tomcat.sh test_brava_mp.sh"


#Create logs directory if it doesnt exist
if [[ ! -d "$SCRIPT_ROOT/logs/" ]]
then
        mkdir -p "$SCRIPT_ROOT/logs/"
        touch "$SCRIPT_ROOT/logs/crontab.log"
        chown -R $SUDO_USER:$SUDO_GROUP "$SCRIPT_ROOT/logs/"
        chmod -R +rw "$(dirname $(readlink -f $0))/logs/"
fi

if [[ ! -f "$SCRIPT_ROOT/logs/monitoring.log.$_DAY" ]]
then
        touch "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
        chown -R $SUDO_USER:$SUDO_GROUP "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
        chmod +rw "$SCRIPT_ROOT/logs/monitoring.log.$_DAY"
fi

# Execute the scripts, send the notification if a script is already running
for _RUNNER_NAME in $RUNNERS; do
        if pgrep "${_RUNNER_NAME%.*}">/dev/null 2>&1
          then
                echo "$_RUNNER_NAME is already running"
                source "$SCRIPT_ROOT/settings/settings_$STAGE.sh"

                _TIMESTAMP=`date +"%Y-%m-%d %T"`
                _MAIL_BODY="$_TIMESTAMP $HOSTNAME $STAGE monitoring scripts tried to start before previous instance was completed - $_RUNNER_NAME"
                mailx -v -r "$_MAIL_SENDER" -s "[HP OVO] $STAGE $HOSTNAME WARNING monitoring scripts did not start" -S smtp="$SMTP_SERVER" $MAIL_RECEIPIENT <<< $_MAIL_BODY
                unset _TIMESTAMP _MAIL_BODY MAIL_SENDER MAIL_RECEIPIENT SMTP_SERVER HOSTNAME STAGE
                exit 1
          else
                "$SCRIPT_ROOT/runners/$_RUNNER_NAME" > >(tee -a "$SCRIPT_ROOT/logs/crontab.log") 2> >(tee -a "$SCRIPT_ROOT/logs/crontab.log" "$SCRIPT_ROOT/logs/monitoring.log.$_DAY" >&2)
        fi
done
unset _RUNNER_NAME RUNNERS STAGE _DAY SCRIPT_ROOT _TIMESTAMP _MAIL_BODY
