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


jmsTestD2Method () {
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
    	if [ $DEBUG == 1 ]; then outputHandler "Connecting to $_docbase repository - checking if D2IsJMSRunning exists" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        echo "retrieve,c,dm_method where object_name='D2IsJMSRunning'" > /tmp/checkD2IsJMSRunning.api
        _IAPI_RETURN_MESSAGE=`timeout 60s ${DM_HOME}/bin/iapi ${_docbase}@$HOSTNAME -U${DMUSER} -P -R/tmp/checkD2IsJMSRunning.api 2>&1 </dev/null | grep -v "DM_SESSION_I_SESSION_START" | grep "DM_" | cut -d ']' -f1`
        local _IAPI_RETURN_CODE=$?
	sleep 5
        if [ $TRACE == 1 ]; then outputHandler "_IAPI_RETURN_MESSAGE: '$_IAPI_RETURN_MESSAGE'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        if [[ $_IAPI_RETURN_CODE -ne 0 ]]; then # Process the error path
            outputHandler "Unable to run iapi utility - skipping" "INFO" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            outputHandler "_IAPI_RETURN_CODE (124 - timeout): $_IAPI_RETURN_CODE" "INFO" "$_APPLICATION" "$_OBJECT"
            if [ $DEBUG == 1 ]; then outputHandler "_IAPI_RETURN_MESSAGE: $_IAPI_RETURN_MESSAGE" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        elif [[ $_IAPI_RETURN_MESSAGE == *"DM_API_E_NO_MATCH"* ]]; then # D2IsJMSRunning method was not found
            outputHandler "Unable to access D2IsJMSRunning method on $_docbase repository - skipping" "INFO" "$_APPLICATION" "$_OBJECT"
        else
            echo "apply,c,NULL,DO_METHOD,METHOD,S,D2IsJMSRunning,ARGUMENTS,S,'-docbase_name $_docbase'" > /tmp/checkD2IsJMSRunning.api
            echo "next,c,q0" >> /tmp/checkD2IsJMSRunning.api
            echo "dump,c,q0" >> /tmp/checkD2IsJMSRunning.api
            echo "close,c,q0" >> /tmp/checkD2IsJMSRunning.api

            _IAPI_RESULT=`timeout 60s ${DM_HOME}/bin/iapi ${_docbase}@$HOSTNAME -U${DMUSER} -P -R/tmp/checkD2IsJMSRunning.api |& tee /tmp/checkD2IsJMSRunning.out | grep launch_failed | cut -d ':' -f2`
            _IAPI_RETURN_CODE=$?
	    sleep 5
            if [ $TRACE == 1 ]; then outputHandler "_IAPI_RESULT: '$_IAPI_RESULT'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
            if [ $TRACE == 1 ]; then outputHandler "_IAPI_RETURN_CODE (124 - timeout): $_IAPI_RETURN_CODE" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"; fi

            # Set the message for notification subsystem
            local _MSG="Failed to run D2IsJMSRunning method on the $_docbase repository"
            if [ $TRACE == 1 ]; then outputHandler "_MSG: '${_MSG}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

            if [[ $_IAPI_RETURN_CODE -ne 0 ]]; then # Process the error path
                outputHandler "Unable to run iapi utility - skipping" "INFO" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                outputHandler "_IAPI_RETURN_CODE (124 - timeout): $_IAPI_RETURN_CODE" "INFO" "$_APPLICATION" "$_OBJECT"
                if [ $DEBUG == 1 ]; then outputHandler "_IAPI_RETURN_MESSAGE: $_IAPI_RETURN_MESSAGE" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
            elif [[ $_IAPI_RESULT != *"F"* ]]; then
                # Process the error path - failed to run method
                outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/outputi
		cat /tmp/checkD2IsJMSRunning.out
            if [ $DEBUG == 1 ]; then outputHandler "_IAPI_RESULT: '$_IAPI_RESULT'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
            if [ $DEBUG == 1 ]; then outputHandler "_IAPI_RETURN_CODE (124 - timeout): $_IAPI_RETURN_CODE" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"; fi
                _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
            else
                # Process the normal state path
                outputHandler "D2IsJMSRunning run succesfully on $_docbase repository" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
                _ARRAY_DOCBASES[${#_ARRAY_DOCBASES[@]}]="$_docbase"
            fi
        fi

       # Cleanup
        rm -f /tmp/checkD2IsJMSRunning.api
	rm -f /tmp/checkD2IsJMSRunning.out
        unset _IAPI_RETURN_MESSAGE
        unset _IAPI_RESULT
        unset _MSG
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              
