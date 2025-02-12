#!/bin/bash
# Flags for controlling if the monitor is currently enabled,
enable='1'

# Check if the monitoring is enabled
if [ $enable == 0 ]
    then
        exit
fi

#Configuration variables
SUDO_USER='dmadmin'
SUDO_GROUP='dmadmin'
_DAY=$(date +%F)
SCRIPT_ROOT=$(dirname $(readlink -f $0))
STAGE='PROD'  # This value is not relevant. STAGE value is taken from 
# /usr2/local/dmadmin/.bash_profile  -->  export STAGE='DEV'
# JMS_VERSION=$(sudo -Hiu $SUDO_USER env | grep DM_JMS_HOME | cut -d "=" -f2);   
# Variable was defined in setting_<>.sh but we are taking system's variables DM_JMS_HOME instead

# List runners
# Content Server:
#       test_cs_database.sh  --> databaseTestConnection
#       test_cs_jms_d2_tomcat.sh -->  jmsCountProcessTomcat, jmsTestConnection ,  docbaseTestConnection , jmsTestD2Method
#       test_cs_xplore.sh --> xploreTestDsearch , xploreTestIndexagent
#       test_cs_nfs_mp.sh --> nfsMountPointTester.sh
#       test_dmagentexec_processes.sh --> dmagentexecTestProcesses.sh
# xPLore
#       test_xplore.sh --> xploreCountProcess
#       test_xplore_watchdog.sh --> xploreWatchdogProcess
RUNNERS="test_cs_database.sh test_cs_jms_d2_tomcat.sh test_dmagentexec_processes.sh test_cs_xplore.sh test_cs_nfs_mp.sh"


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
                sudo -u $SUDO_USER  "$SCRIPT_ROOT/runners/$_RUNNER_NAME" > >(tee -a "$SCRIPT_ROOT/logs/crontab.log") 2> >(tee -a "$SCRIPT_ROOT/logs/crontab.log" "$SCRIPT_ROOT/logs/monitoring.log.$_DAY" >&2)
        fi
done
unset _RUNNER_NAME RUNNERS SUDO_USER SUDO_GROUP STAGE _DAY SCRIPT_ROOT _TIMESTAMP _MAIL_BODY
