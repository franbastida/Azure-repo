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
source $SCRIPT_ROOT/modules/docbaseCountProcess.sh
source $SCRIPT_ROOT/modules/docbaseTestConnection.sh
source $SCRIPT_ROOT/modules/docbrokerCountProcess.sh
source $SCRIPT_ROOT/modules/docbrokerTestConnection.sh

# Settings for arugments passed to opcmsg and e-mail calls
_APPLICATION='Documentum'
_CONFLUENCE_LINK="https://confluence.basf.net/display/DTL/Documentum+Server+-+repository+services+are+not+working+properly"
_SEVERITY="warning"
_OBJECT="docbase"

### LOCAL
# Check if docbrokers are running on server
_OBJECT="docbroker"
outputHandler "## Running RUNNER: test_cs_local.sh - MODULE: docbrokerCountProcess ##" "INFO" "$_APPLICATION" "$_OBJECT"
docbrokerCountProcess rcNormalProc rcErrorProc rcDocbrokers rcDocbrokerPorts "SEVERITY[$_SEVERITY]"
itemStateHandler "docbrokerCountProcess" "$_SEVERITY" "${rcNormalProc[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
itemStateHandler "docbrokerCountProcess" "$_SEVERITY" "${rcErrorProc[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
if [ $TRACE == 1 ]; then outputHandler "rcNormalProc: ${rcNormalProc[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
if [ $TRACE == 1 ]; then outputHandler "rcErrorProc: ${rcErrorProc[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
if [ $TRACE == 1 ]; then outputHandler "rcDocbrokers: ${rcDocbrokers[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
if [ $TRACE == 1 ]; then outputHandler "rcDocbrokerPorts: ${rcDocbrokerPorts[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

# Run further tests if there is a docbroker available on server
if [ "${rcNormalProc[@]}" != "NORMAL[]" ]; then
    ### LOCAL
    # Check if docbroker can be connected to
    _OBJECT="docbroker"
    outputHandler "## Running RUNNER: test_cs_local.sh - MODULE: docbrokerTestConnection ##" "INFO" "$_APPLICATION" "$_OBJECT"
    docbrokerTestConnection rcNormalConn rcErrorConn rcDocbrokerPortsLocal "SEVERITY[$_SEVERITY]" "DOCBROKER_PORTS_NATIVE[${rcDocbrokerPorts[*]}]" 
    itemStateHandler "docbrokerTestConnection" "$_SEVERITY" "${rcNormalConn[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
    itemStateHandler "docbrokerTestConnection" "$_SEVERITY" "${rcErrorConn[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
    if [ $TRACE == 1 ]; then outputHandler "rcNormalConn: ${rcNormalConn[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "rcErrorConn: ${rcErrorConn[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    # Test connection to the local instance of docbase if there is a docbroker running on 1489 native port available
    if [[ ! "$rcErrorConn" == *"1489"* ]]; then
        ### LOCAL
        _OBJECT="docbase"
        # Check if docbases are running on server
        outputHandler "## Running RUNNER: test_cs_local.sh - MODULE: docbaseCountProcess ##" "INFO" "$_APPLICATION" "$_OBJECT"
        docbaseCountProcess rcNormal rcError rcDocbases "SEVERITY[$_SEVERITY]"
        itemStateHandler "docbaseCountProcess" "$_SEVERITY" "${rcNormal[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        itemStateHandler "docbaseCountProcess" "$_SEVERITY" "${rcError[@]}" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        if [ $TRACE == 1 ]; then outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        unset rcNormal rcError

        ### LOCAL
        # Check connection to the local instance of docbase
        _OBJECT="docbase"
        outputHandler "## Running RUNNER: test_cs_local.sh - MODULE: docbaseTestConnection ##" "INFO" "$_APPLICATION" "$_OBJECT"
        docbaseTestConnection rcNormal rcError rcDocbasesLocal "SEVERITY[$_SEVERITY]" "DOCBASES[${rcDocbases[*]}]" "SCOPE[local]"
        itemStateHandler "docbaseTestConnection" "$_SEVERITY" "${rcNormal[@]} - local instance" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        itemStateHandler "docbaseTestConnection" "$_SEVERITY" "${rcError[@]} - local instance" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        if [ $TRACE == 1 ]; then outputHandler "rcNormal: ${rcNormal[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "rcError: ${rcError[*]}" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        unset rcNormal rcError
    fi
fi

# Final variable cleanup
unset rcDocbases rcDocbasesLocal rcDocbrokers rcDocbrokerPorts rcDocbrokerPortsLocal rcNormalConn rcErrorConn
unset _OBJECT _APPLICATION _CONFLUENCE_LINK _SEVERITY

#restore IFS
IFS="$ORIGINAL_IFS"

# Create status page
if [ $VISUALISATION_ENABLED == 1 ]; then bash $SCRIPT_ROOT/visualisation/parser.sh; fi
