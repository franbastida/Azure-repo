#!/bin/bash
# Flags for controlling if the monitor is currently enabled, 
# if opcmsg notifications are sent to Operation Manager and if mails are sent
OPCMSG_ENABLED='1'
MAIL_ENABLED='1'
VISUALISATION_ENABLED='1'
DEBUG='1'
TRACE='0'
MAX_VERBOSITY='0'
STDOUT='1' # print output to stdout
enable='1'

# Load profile variables
if [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile"
fi

# Check if the monitoring is enabled
if [ $enable == 0 ] 
    then
        exit
fi

# Check if the monitoring is enabled
if [ -z "$STAGE" ]
    then
        echo "No STAGE environment variable is set - unable to load proper settings file."
        exit
fi

# Set required variables
ORIGINAL_IFS="$IFS"
EXECUTION_ID=`cat /dev/urandom | tr -dc '0-9a-f' | fold -w 16 | head -n 1`
#EXECUTION_ID=`date "+%Y%m%d%H%M%S"`
#CALLER_SCRIPT_NAME=${0##*/}
#EXECUTION_ID+="_$CALLER_SCRIPT_NAME"

# Load environment-specific variables
SCRIPT_ROOT=$(dirname $(readlink -f $0))
SCRIPT_ROOT="$(dirname "$SCRIPT_ROOT")"
source "$SCRIPT_ROOT/settings/settings_$STAGE.sh"

if [ -f "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh" ]; then
    source "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
    echo "loaded host specific configuration: $SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
fi

# Fix for running additional wrapper for the script
cd $SCRIPT_ROOT

# Load modules necessary for all scripts
source $SCRIPT_ROOT/modules/notificationHandler.sh
source $SCRIPT_ROOT/modules/outputHandler.sh
source $SCRIPT_ROOT/modules/itemStateHandler.sh
source $SCRIPT_ROOT/modules/inputParameterHandler.sh


# Load other modules
source $SCRIPT_ROOT/modules/tomcatCountProcess.sh
source $SCRIPT_ROOT/modules/networkCheckWebapp.sh

# Settings for arugments passed to opcmsg and e-mail calls
_APPLICATION='Documentum'
_CONFLUENCE_LINK="https://confluence.basf.net/display/DTL/Apache+Tomcat+is+not+working+properly"
_SEVERITY="warning"
_OBJECT="Tomcat"

### LOCAL
# Check if Tomcat is running on server
_OBJECT="Tomcat"
outputHandler "## Running RUNNER: test_tomcat.sh - MODULE: tomcatCountProcess ##" "INFO" "$_APPLICATION" "$_OBJECT"
tomcatCountProcess rcNormal rcError "SEVERITY[$_SEVERITY]" $TOMCAT_LIST
itemStateHandler "tomcatCountProcess" "$_SEVERITY" "${rcNormal[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
itemStateHandler "tomcatCountProcess" "$_SEVERITY" "${rcError[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
if [ $TRACE == 1 ]; then outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
if [ $TRACE == 1 ]; then outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

# Check Tomcat-Content Server connnectivity performance
_OBJECT="Tomcat"
outputHandler "## Running RUNNER: test_tomcat.sh - MODULE: networkCheckWebapp ##" "INFO" "$_APPLICATION" "$_OBJECT"
networkCheckWebapp rcNormal rcError "SEVERITY[$_SEVERITY]" $TOMCAT_LIST
itemStateHandler "networkCheckWebapp" "$_SEVERITY" "${rcNormal[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
itemStateHandler "networkCheckWebapp" "$_SEVERITY" "${rcError[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
if [ $TRACE == 1 ]; then outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
if [ $TRACE == 1 ]; then outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

# Final variable cleanup
unset rcNormal rcError
unset _OBJECT _APPLICATION _CONFLUENCE_LINK _SEVERITY

#restore IFS
IFS="$ORIGINAL_IFS"

# Create status page
if [ $VISUALISATION_ENABLED == 1 ]; then bash $SCRIPT_ROOT/visualisation/parser.sh; fi

