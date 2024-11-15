#!/bin/bash
# Test the connection to the repositories (docbases)
# Function takes 4 required parameters:
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# $3 for storing list of repositories (docbases) with successful connection estabilished in the test
# SEVERITY[level] for proper level being written to host

### Usage: docbaseTestConnection ()
### Example: docbaseTestConnection rcNormal rcError rcDocbases "SEVERITY[warning]"
### Example - override list of docbases: docbaseTestConnection rcNormal rcError rcDocbases "SEVERITY[warning]" "DOCBASES[develop Engineering]"


docbaseTestConnection () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _RESULTVAR_DOCBASES=$3
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    local _ARRAY_DOCBASES=()
    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_DOCBASES[@]} -eq 0 ]; then
        # Get list of all docbases on the server
        _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
    fi

    if [ -z "$_SCOPE" ]; then
        # set scope to local - try to connect to the local repository instance
        _SCOPE="global"
    fi

    for _docbase in "${_DOCBASES[@]}";
    do
        if [ $DEBUG == 1 ]; then outputHandler "Checking connection to $_docbase repository - $_SCOPE scope" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        if [ "$_SCOPE" == "local" ]; then
            local _IDQL="${DM_HOME}/bin/idql ${_docbase}@$HOSTNAME -U${DMUSER} -P -n"
        else
            local _IDQL="${DM_HOME}/bin/idql ${_docbase} -U${DMUSER} -P -n"
        fi

       #using global variable to enable exit code capture
               _QUERY_RESULT=`timeout 60s ${_IDQL} 2>&1 << dqlQuery
select count(*) from dm_server_config;
go
dqlQuery
`
        local _IDQL_RETURN_CODE=$?
        sleep 10
        if [ $DEBUG == 1 ]; then outputHandler "_IDQL: $_IDQL" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $DEBUG == 1 ]; then outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $DEBUG == 1 ]; then outputHandler "_IDQL_RETURN_CODE: $_IDQL_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        ### Error handling block
        local _MSG="Error connecting to the $_docbase repository - $_SCOPE scope"


        if [[ $_IDQL_RETURN_CODE -ne 0 ]]; # condition to determine error
        then # Process the error path
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            outputHandler "_IDQL_RETURN_CODE (124 - timeout): $_IDQL_RETURN_CODE" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else # Process the normal state path
            outputHandler "Successful connection to $_docbase repository" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
            _ARRAY_DOCBASES[${#_ARRAY_DOCBASES[@]}]="$_docbase"

        fi

        # Loop variables cleanup
        unset _IDQL
        unset _QUERY_RESULT
        unset _IDQL_RETURN_CODE
        unset _MSG
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    eval $_RESULTVAR_DOCBASES="\"${_ARRAY_DOCBASES[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}