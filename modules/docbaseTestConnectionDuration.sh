#!/bin/bash
# Count the processes for repositories on host

### Usage: docbaseCountProcess ()
### Example: docbaseCountProcess warning
### Example - override list of docbases: docbaseCountProcess warning "DOCBASES[develop Engineering]"

docbaseTestConnectionDuration () {
######################################################################
### Settings for notification mechanism
    local _APPLICATION='Documentum'
    local _OBJECT="docbase"
    local _CONFLUENCE_LINK="http://localhost.localdomain"

### Calculating values from input parameters
    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_DOCBASES[@]} -eq 0 ]; then
        # Get list of all docbases on the server
        _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
    fi

    for _docbase in "${_DOCBASES[@]}";
    do
        if [ $DEBUG == 1 ]; then outputHandler "Checking connection to $_docbase repository" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        local _START_DATE=$(date +"%s")
        local _IDQL="${DM_HOME}/bin/idql ${_docbase}@$HOSTNAME -U${DMUSER} -P -n"

        #using global variable to enable exit code capture
        _QUERY_RESULT=`${_IDQL} 2>&1 << dqlQuery
select count(*) from dm_server_config;
go
dqlQuery
`
        local _IDQL_RETURN_CODE=$?
        local _END_DATE=$(date +"%s")
        local _DURATION=$(($_END_DATE-$_START_DATE))
        if [ $TRACE == 1 ]; then outputHandler "_START_DATE: $_START_DATE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_IDQL: $_IDQL" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_IDQL_RETURN_CODE: $_IDQL_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_END_DATE: $_END_DATE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_DURATION: $_DURATION" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        # Check the repository connection return de
        local _MSG="Warning: Connection to $_docbase exceeded 3 minutes" 
        local _DETAILS="Connection to $_docbase took $(($_DURATION / 60)) minutes and $(($_DURATION % 60)) seconds"

        if [[ $(($_DURATION / 60)) -gt 3 ]]; then
            # Process the error path
            outputHandler "$_MSG: $_DETAILS" "INFO" "$_APPLICATION" "$_OBJECT"
            itemStateHandler "docbaseTestConnection" "$_SEVERITY" "$_MSG" "ERROR" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        else
            # Process the normal state path
            outputHandler "$_DETAILS" "INFO" "$_APPLICATION" "$_OBJECT"
            itemStateHandler "docbaseTestConnection" "$_SEVERITY" "$_MSG" "NORMAL" "$_APPLICATION" "$_OBJECT" "$_CONFLUENCE_LINK"
        fi

        # return NORMAL - no error; ERROR(DETAILS) - if error
 
        unset _START_DATE
        unset _IDQL
        unset _QUERY_RESULT
        unset _IDQL_RETURN_CODE
        unset _END_DATE
        unset _DURATION
        unset _MSG
        unset _IDQL_RETURN_MESSAGE
    done

### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}