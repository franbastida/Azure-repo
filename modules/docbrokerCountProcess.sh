#!/bin/bash
# Count the processes for repositories on host
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: docbaseCountProcess ()
### Example: docbaseCountProcess rcNormal rcError "SEVERITY[warning]"
### Example - override list of docbases: docbaseCountProcess rcNormal rcError "SEVERITY[warning]" "DOCBASES[develop Engineering]"


docbrokerCountProcess () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _RESULTVAR_DOCBROKERS=$3
    local _RESULTVAR_DOCBROKER_PORTS=$4

    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    local _ARRAY_DOCBROKERS=()
    local _ARRAY_DOCBROKER_PORTS=()

    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_DOCBROKERS[@]} -eq 0 ]; then
        # Get list of all docbases on the server
        _DOCBROKERS=(${_DOCBROKERS:-`ls -1 $DOCUMENTUM/dba/docbroker*`})
    fi

    # check each docbroker configuration file to determine name of the docbroker
    for _content in "${_DOCBROKERS[@]}";
    do
        # count number of processes that match the docbroker name
        local _DOCBROKER_PROC_COUNT=${_DOCBROKER_PROC_COUNT:-`ps -fu $DMUSER | grep "./dmdocbroker" | grep "$_content" |  grep -v grep | wc -l`}
        if [ $DEBUG == 1 ]; then outputHandler "_DOCBROKER_PROC_COUNT for $_content: $_DOCBROKER_PROC_COUNT" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        
        # Set the message for notification subsystem
        local _MSG="No docbroker processes are running for $_content" 
        if [ $TRACE == 1 ]; then outputHandler "_MSG: '${_MSG}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        if [[ $_DOCBROKER_PROC_COUNT -lt 1 ]]; then
            # Process the error path
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else
            # Process the normal state path
            outputHandler "$_DOCBROKER_PROC_COUNT processes are running for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
            _ARRAY_DOCBROKERS[${#_ARRAY_DOCBROKERS[@]}]="$_docbase"

            local _port=${_port:-`ps -fu $DMUSER | grep "./dmdocbroker" | grep "$_content" | grep -o "port .* " | cut -d " " -f2`}
            _ARRAY_DOCBROKER_PORTS[${#_ARRAY_DOCBROKER_PORTS[@]}]="$_port"
            unset _port
        fi
        # Variable cleanup for loop
        unset _MSG
        unset _DOCBROKER_PROC_COUNT
        
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    eval $_RESULTVAR_DOCBROKERS="\"${_ARRAY_DOCBROKERS[*]}\""
    eval $_RESULTVAR_DOCBROKER_PORTS="\"${_ARRAY_DOCBROKER_PORTS[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              