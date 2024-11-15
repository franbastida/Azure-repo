#!/bin/bash
# Count the processes for repositories on host
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: docbaseCountProcess ()
### Example: docbaseCountProcess rcNormal rcError "SEVERITY[warning]"
### Example - override list of docbases: docbaseCountProcess rcNormal rcError "SEVERITY[warning]" "DOCBASES[develop Engineering]"


xploreCountProcess () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    inputParameterHandler "$@"

######################################################################
    local _XPLORE_GLOBAL=(${_XPLORE_GLOBAL:-`ls -1d /vg01lv01/xplore/*tomcat*/ | rev | cut -d'/' -f 2 | rev`})
	if [ $DEBUG == 1 ]; then outputHandler "_XPLORE_GLOBAL: '${_XPLORE_GLOBAL[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

    for _xplore_object in "${_XPLORE_GLOBAL[@]}";
    do
        local _XPLORE_PROC_COUNT=`ps -fu $DMUSER | grep "$_xplore_object" |  grep -v grep | wc -l`
        if [ $DEBUG == 1 ]; then outputHandler "_XPLORE_PROC_COUNT for '$_xplore_object': $_XPLORE_PROC_COUNT" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        # Set the message for notification subsystem
        local _MSG="No documentum processes found for $_xplore_object"
        if [ $TRACE == 1 ]; then outputHandler "_MSG: '${_MSG}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        
        if [[ $_XPLORE_PROC_COUNT -lt 1 ]]; then
            # Process the error path
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else
            # Process the normal state path
            outputHandler "$_DOCBASE_PROC_COUNT processes are running for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
        fi
        unset _MSG
        unset _XPLORE_PROC_COUNT
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              
