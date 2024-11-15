#!/bin/bash
# Test connection to docbrokers
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: docbrokerTestConnection ()
### Example: docbrokerTestConnection rcNormal rcError "SEVERITY[warning]"
### Example - override list of docbrokers and ports: docbrokerTestConnection rcNormal rcError "SEVERITY[warning]" "DOCBROKERS[docbroker]" "DOCBROKER_PORTS_NATIVE[1489]"


docbrokerTestConnection () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _RESULTVAR_DOCBROKER_PORTS=$3
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    local _ARRAY_DOCBROKER_PORTS=()
    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_DOCBROKER_PORTS_NATIVE[@]} -eq 0 ]; then
        # Get list of all docbrokers on the server
        local _DOCBROKER_PORTS_NATIVE=(${_DOCBROKER_PORTS_NATIVE:-`cat $DOCUMENTUM/dba/dm_documentum_config.txt | grep PORT | cut -d '=' -f2`})
    fi

    for _port in "${_DOCBROKER_PORTS_NATIVE[@]}"
    do
        if [ $DEBUG == 1 ]; then outputHandler "Checking connection to docbroker on $_port" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        _DMQDOCBROKER_RESULT=`dmqdocbroker -t $HOSTNAME -p $_port -c ping`
        local _DMQDOCBROKER_RETURN_CODE=$?

	sleep 5

        if [ $TRACE == 1 ]; then outputHandler "_DMQDOCBROKER_RESULT: $_DMQDOCBROKER_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_DMQDOCBROKER_RETURN_CODE: $_DMQDOCBROKER_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        ### Error handling block
        local _MSG="Connection to docbroker listening on port $_port failed"

        if [[ $_DMQDOCBROKER_RETURN_CODE -ne 0 ]]; # condition to determine error
        then # Process the error path
        if [ $DEBUG == 1 ]; then outputHandler "_DMQDOCBROKER_RESULT: $_DMQDOCBROKER_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $DEBUG == 1 ]; then outputHandler "_DMQDOCBROKER_RETURN_CODE: $_DMQDOCBROKER_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else # Process the normal state path
            outputHandler "Successful connection to docbroker listening on port $_port" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
            _ARRAY_DOCBROKER_PORTS[${#_ARRAY_DOCBROKER_PORTS[@]}]="$_port"
        fi
        unset _DMQDOCBROKER_RESULT
    done
        
######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    eval $_RESULTVAR_DOCBROKER_PORTS="\"${_ARRAY_DOCBROKER_PORTS[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              
