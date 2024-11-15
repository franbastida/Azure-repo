#!/bin/bash
# Count the processes for repositories on host

### Usage: jmsCountProcessTomcat ()
### Example: jmsCountProcessTomcat "SEVERITY[warning]"


jmsCountProcessTomcat () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    inputParameterHandler "$@"
######################################################################
### Main body
    local _JMS_PROC_COUNT=${_JMS_PROC_COUNT:-`ps -fu $DMUSER --cols 500 | grep "java" | grep "$DM_JMS_HOME" |  grep -v grep | wc -l`}
    if [ $TRACE == 1 ]; then outputHandler "_JMS_PROC_COUNT: '${_JMS_PROC_COUNT}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    # Set the message for notification subsystem
    local _MSG="No Java Method Server processes are running"
    if [ $TRACE == 1 ]; then outputHandler "_MSG: '${_MSG}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    if [[ $_JMS_PROC_COUNT -lt 1 ]]; then
        # Process the error path
        outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
        _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
    else
        # Process the normal state path
        outputHandler "$_JMS_PROC_COUNT processes are running for Java Method Server" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
        _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
    fi
######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
             