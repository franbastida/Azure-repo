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
source $SCRIPT_ROOT/modules/jmsCountProcessTomcat.sh
source $SCRIPT_ROOT/modules/jmsTestConnection.sh
source $SCRIPT_ROOT/modules/jmsTestD2Method.sh
source $SCRIPT_ROOT/modules/docbaseTestConnection.sh

# Settings for arugments passed to opcmsg and e-mail calls
_APPLICATION='Documentum'
_CONFLUENCE_LINK="https://confluence.basf.net/display/DTL/Documentum+Server+-+Java+Method+Server+(JMS)+service+is+not+working+properly"
_SEVERITY="warning"
_OBJECT="JMS"

### LOCAL
# Check if JMS is running on server
_OBJECT="JMS"
outputHandler "## Running RUNNER: test_cs_jms_d2_tomcat.sh - MODULE: jmsCountProcessTomcat ##" "INFO" "$_APPLICATION" "$_OBJECT"
jmsCountProcessTomcat rcNormalProc rcErrorProc "SEVERITY[$_SEVERITY]"
itemStateHandler "jmsCountProcessTomcat" "$_SEVERITY" "${rcNormalProc[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
itemStateHandler "jmsCountProcessTomcat" "$_SEVERITY" "${rcErrorProc[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"

# Run further tests if there is a JMS available on server
if [ "${rcNormalProc[@]}" != "NORMAL[]" ]; then
### LOCAL

    # Check if connection to JMS DmMethod endpoint is possible
    _OBJECT="JMSConnection"
    outputHandler "## Running RUNNER: test_cs_jms_d2_tomcat.sh - MODULE: jmsTestConnection ##" "INFO" "$_APPLICATION" "$_OBJECT"
    jmsTestConnection rcNormal rcError "SEVERITY[$_SEVERITY]"
    itemStateHandler "jmsTestConnection" "$_SEVERITY" "${rcNormal[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
    itemStateHandler "jmsTestConnection" "$_SEVERITY" "${rcError[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
    unset rcNormal rcError

    # Check connection to the global instance of docbase
    _OBJECT="docbase"
    outputHandler "## Running RUNNER: test_cs_jms_d2_tomcat.sh - MODULE: docbaseTestConnection ##" "INFO" "$_APPLICATION" "$_OBJECT"
    docbaseTestConnection rcNormal rcError rcDocbasesGlobal "SEVERITY[$_SEVERITY]" "SCOPE[local]"
    if [ $TRACE == 1 ]; then outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    unset rcNormal rcError

    # Check if JMSD2 DmMethod is running
    _OBJECT="JMSD2"
    if [ $TRACE == 1 ]; then
        outputHandler "## Running RUNNER: test_cs_jms_d2_tomcat.sh - MODULE: jmsTestD2Method ##" "INFO" "$_APPLICATION" "$_OBJECT"
        jmsTestD2Method rcNormal rcError "SEVERITY[$_SEVERITY]" "DOCBASES[${rcDocbasesGlobal[*]}]";
        itemStateHandler "jmsTestD2Method" "$_SEVERITY" "${rcNormal[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK";
        itemStateHandler "jmsTestD2Method" "$_SEVERITY" "${rcError[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK";
        outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT";
        outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; 
    fi
    unset rcNormal rcError
    
fi
# Final variable cleanup
unset rcNormalProc rcErrorProc rcDocbasesGlobal
unset _OBJECT _APPLICATION _CONFLUENCE_LINK _SEVERITY

#restore IFS
IFS="$ORIGINAL_IFS"

# Create status page
if [ $VISUALISATION_ENABLED == 1 ]; then bash $SCRIPT_ROOT/visualisation/parser.sh; fi

