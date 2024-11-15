#!/bin/bash
# Test the xPlore IndexAgent state
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: xploreTestIndexagent ()
### Example: xploreTestIndexagent rcNormal rcError "SEVERITY[warning]"
### Example - override list of docbases: xploreTestIndexagent rcNormal rcError rcDocbases "SEVERITY[warning]" "DOCBASES[develop Engineering]"


xploreTestIndexagent () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    inputParameterHandler "$@"
######################################################################

### Main body
    if [ ${#_DOCBASES[@]} -eq 0 ]; then
        # Get list of all docbases on the server
        _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
    fi

    for _docbase in "${_DOCBASES[@]}";
    do
        if [ $DEBUG == 1 ]; then outputHandler "Checking IndexAgent connection for $_docbase repository - getting dm_ftindex_agent_config object" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        # Define the idql program location and connection arguments
        local _IDQL="${DM_HOME}/bin/idql ${_docbase} -U${DMUSER} -P -n"
        
        
        # Run the idql query for obtaining configuration about IndexAgent for specified docbase
        _QUERY_RESULT=`timeout 60s ${_IDQL} <<_EOF_
select object_name,':',index_name from dm_ftindex_agent_config
go
_EOF_
`
        # Save the idql application exit code
        local _IDQL_RETURN_CODE=$?
        if [ $TRACE == 1 ]; then outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        if [[ $_IDQL_RETURN_CODE -ne 0 ]]; # condition to determine error
        then # Process the error path
            local _MSG="Error connecting to the $_docbase repository - unable to obtain IndexAgent configuration - skipping"
            outputHandler "$_MSG" "INFO" "$_APPLICATION" "$_OBJECT"
            if [ $DEBUG == 1 ]; then outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi	
            if [ $DEBUG == 1 ]; then outputHandler "_IDQL_RETURN_CODE (124 - timeout): $_IDQL_RETURN_CODE" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi	
        else
        # Run the verification if docbase is running and has IndexAgent defined
            local _indexagent_index_name=${_indexagent_index_name:-`grep ftindex_01 <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
            local _indexagent_object_name=${_indexagent_object_name:-`grep ftindex_01 <<< "$_QUERY_RESULT" | cut -d ':' -f1 | xargs`}
            if [ $TRACE == 1 ]; then outputHandler "_indexagent_index_name: '${_indexagent_index_name}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
            if [ $TRACE == 1 ]; then outputHandler "_indexagent_object_name: '${_indexagent_object_name}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

            if [ -z "$_indexagent_object_name" ];
            then
                _MSG="No IndexAgent configuration found for $_docbase"
                outputHandler "$_MSG" "INFO" "$_APPLICATION" "$_OBJECT"
            else
                if [ $DEBUG == 1 ]; then outputHandler "Checking IndexAgent connection for $_docbase repository - checking IndexAgent state" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

                # Define the iapi program location and connection arguments
                local _IAPI="timeout 60s ${DM_HOME}/bin/iapi ${_docbase} -U${DMUSER} -P"
                # Run the iapi query for obtaining configuration about IndexAgent state for specified docbase
                _IAPI_RESULT=`${_IAPI} <<_EOF_
apply,c,,FTINDEX_AGENT_ADMIN,NAME,S,${_indexagent_index_name},AGENT_INSTANCE_NAME,S,${_indexagent_object_name},ACTION,S,status
next,c,q0
dump,c,q0
close,c,q0
_EOF_
`
                # Save the iapi application exit code
                local _IAPI_RETURN_CODE=$?
                if [ $TRACE == 1 ]; then outputHandler "_IAPI_RESULT: $_IAPI_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                if [ $TRACE == 1 ]; then outputHandler "_IAPI_RETURN_CODE: $_IAPI_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

                if [[ $_IAPI_RETURN_CODE -ne 0 ]]; then # Process the error path
                    outputHandler "Unable to run iapi utility - skipping" "INFO" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                    outputHandler "_IAPI_RETURN_CODE (124 - timeout): $_IAPI_RETURN_CODE" "INFO" "$_APPLICATION" "$_OBJECT"
                    if [ $DEBUG == 1 ]; then outputHandler "_IAPI_RETURN_MESSAGE: $_IAPI_RETURN_MESSAGE" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
                else
                    local _indexagent_status=`grep status <<< "$_IAPI_RESULT" |  cut -d ':' -f2 | xargs`
                    if [ $TRACE == 1 ]; then outputHandler "_indexagent_status: $_indexagent_status" "TRACE" "$_APPLICATION" "$_OBJECT"; fi      
                    
                    # Define the error message for notification
                    local _MSG="IndexAgent for ${_docbase} is not working in normal or reindex mode (it is either 200 - shutdown or 100 - stopped)"
                    if [ $_indexagent_status != '0' ]; then
                        # Process the error path
                        outputHandler "$_MSG - status $_indexagent_status" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                        _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
                    else
                        # Process the normal state path
                        outputHandler "xPlore dsearch is working in normal mode for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                        _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
                    fi
                fi  

                unset _indexagent_index_name
                unset _indexagent_object_name
                unset _IAPI
                unset _QUERY_RESULT
                unset _IDQL_RETURN_CODE
                unset _MSG
            fi
        fi
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              
