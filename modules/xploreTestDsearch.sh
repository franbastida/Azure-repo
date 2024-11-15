#!/bin/bash
# Count the processes for Documentum xPlore dsearch service running on host
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: xploreTestDsearch ()
### Example: xploreTestDsearch rcNormal rcError rcDocbases "SEVERITY[warning]"
### Example - override list of docbases: xploreTestDsearch rcNormal rcError rcDocbases "SEVERITY[warning]" "DOCBASES[develop Engineering]"


xploreTestDsearch () {
### Setting required initial variables and calculating values from input parameters
    local _SINGLE_INSTANCE='1'
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
    	outputHandler "Checking xplore connection for $_docbase repository" "INFO" "$_APPLICATION" "$_OBJECT"

        # Define the idql program location and connection arguments
        local _IDQL="${DM_HOME}/bin/idql ${_docbase} -U${DMUSER} -P -n"
        # Run the idql query for obtaining configuration about dsearch for specified docbase
        _QUERY_RESULT=`timeout 30s ${_IDQL} <<_EOF_
select param_name,':',param_value from dm_ftengine_config;
go
_EOF_
`
        # Save the idql application exit code
        local _IDQL_RETURN_CODE=$?

        if [[ $_IDQL_RETURN_CODE -ne 0 ]]; # condition to determine error
        then # Process the error path
            local _MSG="Error connecting to the $_docbase repository - unable to obtain xPlore location - skipping"
            outputHandler "$_MSG" "INFO" "$_APPLICATION" "$_OBJECT"
            outputHandler "_IDQL_RETURN_CODE (124 - timeout): $_IDQL_RETURN_CODE" "INFO" "$_APPLICATION" "$_OBJECT"
            if [ $DEBUG == 1 ]; then outputHandler "_QUERY_RESULT: $_QUERY_RESULT" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi	
        else
        # Run the verification if docbase is running
            local _dsearch_qrserver_protocol=${_dsearch_qrserver_protocol:-`grep dsearch_qrserver_protocol <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
            if [ $TRACE == 1 ]; then outputHandler "_dsearch_qrserver_protocol: '${_dsearch_qrserver_protocol}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

            if [ -z "$_dsearch_qrserver_protocol" ];
            then
                local _MSG="No dSearch configuration found in repository, skipping"
                outputHandler "$_MSG" "INFO" "$_APPLICATION" "$_OBJECT"
            else
            # Run the verification if docbase has dsearch defined (Only executed ONCE)

                # fixing curl issue "error: /usr/lib64/libssh.so.4: undefined symbol"
                local LD_LIBRARY_PATH=

                # Construct the dsearch service url
                local _dsearch_qrserver_host=${_dsearch_qrserver_host:-`grep dsearch_qrserver_host <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
                local _dsearch_qrserver_port=${_dsearch_qrserver_port:-`grep dsearch_qrserver_port <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
                local _dsearch_qrserver_target=${_dsearch_qrserver_target:-`grep dsearch_qrserver_target <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
                if [ $TRACE == 1 ]; then outputHandler "_dsearch_qrserver_host: '${_dsearch_qrserver_host}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                if [ $TRACE == 1 ]; then outputHandler "_dsearch_qrserver_port: '${_dsearch_qrserver_port}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                if [ $TRACE == 1 ]; then outputHandler "_dsearch_qrserver_target: '${_dsearch_qrserver_target}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                
                if [ $DEBUG == 1 ]; then outputHandler "Checking xPlore service url: '${_dsearch_qrserver_protocol}://${_dsearch_qrserver_host}:${_dsearch_qrserver_port}${_dsearch_qrserver_target}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
                local _curl_result=${_curl_result:-`curl -s ${_dsearch_qrserver_protocol}://${_dsearch_qrserver_host}:${_dsearch_qrserver_port}${_dsearch_qrserver_target}`}
                if [ $TRACE == 1 ]; then outputHandler "_curl_result: '${_curl_result}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

                # Define the error message for notification
                # Change message to point to the server instead of docbase if setting for single instance check was configured
                if [ $_SINGLE_INSTANCE == 1 ]; then 
                    local _MSG="xPlore dsearch is not working properly on $_dsearch_qrserver_host"
                else
                    local _MSG="xPlore dsearch is not working properly for $_docbase"
                fi
                if [[ ! $_curl_result = *normal* ]]; then
                    # Process the error path
                    outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                    _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors

                    # Break out of the loop if setting for single instance check was configured
                    if [ $_SINGLE_INSTANCE == 1 ]; then 
                        break
                    fi
                else
                    # Process the normal state path
                    outputHandler "xPlore dsearch is working in normal mode for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                    _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error

                    # Break out of the loop if setting for single instance check was configured
                    if [ $_SINGLE_INSTANCE == 1 ]; then 
                        break
                    fi
                fi
            fi

            unset _dsearch_qrserver_host
            unset _dsearch_qrserver_port
            unset _dsearch_qrserver_target
            unset __url_result
            unset _IDQL
            unset _QUERY_RESULT
            unset _IDQL_RETURN_CODE
            unset _MSG 
        fi
        unset _dsearch_qrserver_protocol
    done
	
######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}                                                                                                                                                                                              