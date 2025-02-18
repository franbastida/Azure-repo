#!/bin/bash
# Test the presence of process dm_agent_agent for all the docbases running in the documentum server
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: dmagentexecCountProcess ()
### Example: dmagentexecCountProcess rcNormal rcError "SEVERITY[warning]"
### Example - override list of docbases: dmagentexecCountProcess rcNormal rcError "SEVERITY[warning]" "DOCBASES[develop Engineering]"


dmagentexecCountProcess () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _RESULTVAR_DOCBASES=$3
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    local _ARRAY_DOCBASES=()
    local _ARRAY_FAIL_DOCBASES=()
    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_ARRAY_DOCBASES[@]} -eq 0 ]; then
        # Get list of all docbases on the server with teh expression :-
        _ARRAY_DOCBASES=(${_ARRAY_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
    fi
    
    if [ $DEBUG == 1 ]; then outputHandler "Running dm_agent_exec test of docbases: '${_ARRAY_DOCBASES[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

    local _MSG="No dm_agent_exec process found for at least one docbase"

    for _docbase in "${_ARRAY_DOCBASES[@]}";
    do
        if [ $DEBUG == 1 ]; then outputHandler "Running dm_agent_exec process test for docbase: '${_docbase}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        
        # Count processes for docbase
        local _DOCBASE_AGENT_EXEC_PROC_COUNT=`ps -fu $DMUSER | grep "./dm_agent_exec" | grep $_docbase | grep -v grep | wc -l`
        if [[ $_DOCBASE_AGENT_EXEC_PROC_COUNT -lt 1 ]]; then
            # Proceed with notification ERROR
            local _MSG_error="ERROR -> No dm_agent_exec process found for $_docbase"
            outputHandler "$_MSG_error" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_FAIL_DOCBASES+=($_docbase)
        else
            outputHandler "$_DOCBASE_AGENT_EXEC_PROC_COUNT dm_agent_exec processes are running for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
        fi
     done
     
    #Processing the errors/normal arrays
     if [[ ${#_ARRAY_FAIL_DOCBASES[*]} -lt 1 ]]; then
        # Process the normal path
        _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
     else
        # Process the error state path
        outputHandler "No dm_agent_exec process found for at least one docbase ${_ARRAY_FAIL_DOCBASES[*]}" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
        _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
     fi
     
     unset _MSG
     unset _MSG_error
     unset _ARRAY_DOCBASES
     unset _DOCBASE_PROC_COUNT
   

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    eval $_RESULTVAR_DOCBASES="\"${_ARRAY_DOCBASES[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              