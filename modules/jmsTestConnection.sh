#!/bin/bash
# Count the processes for repositories on host

### Usage: jmsTestConnection ()
### Example: jmsTestConnection "SEVERITY[warning]"


jmsTestConnection () {
### Setting required initial variables and calculating values from input parameters
    # fixing curl issue "error: /usr/lib64/libssh.so.4: undefined symbol"
    local LD_LIBRARY_PATH=
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    inputParameterHandler "$@"

    local _JMS_PATH=$(find $DM_JMS_HOME/ -name DctmServer_MethodServer -type d -printf "%h\n")

    if [ $TRACE == 1 ]; then outputHandler "_JMS_PATH: $_JMS_PATH" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    if [ ! -d "$_JMS_PATH" ]; then
        echo "Java Method Server not found in $DM_JMS_HOME/"
    else
        local _CONFIG_PATH=$(find $_JMS_PATH -name dctm.properties -type f -not -path "*/template/*"  -not -path "*_DMS/*")
        if [ $TRACE == 1 ]; then outputHandler "_CONFIG_PATH: $_CONFIG_PATH" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

        if [ -r "$_CONFIG_PATH" ]; then
            local _JMS_PORT=${_JMS_PORT:-`cat $_CONFIG_PATH | grep "LISTEN_PORT" | cut -d '=' -f2`}
            if [ $TRACE == 1 ]; then outputHandler "_JMS_PORT: $_JMS_PORT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

            if [ $DEBUG == 1 ]; then outputHandler "Testing JMS connection on http://$HOSTNAME:$_JMS_PORT/DmMethods/servlet/DoMethod" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi   
            local _JMS_TEST_DMMETHODS=${JMS_TEST:-`curl --max-time 5 -s http://$HOSTNAME:$_JMS_PORT/DmMethods/servlet/DoMethod | grep -o "<title>Documentum Java Method Server</title>" | wc -w`}

            if [ $TRACE == 1 ]; then outputHandler "_JMS_TEST_DMMETHODS: $_JMS_TEST_DMMETHODS on http://$HOSTNAME:$_JMS_PORT/DmMethods/servlet/DoMethod" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

            # Set the message for notification subsystem
            local _MSG="Java Method Server is not responding on DmMethods endpoint"
            if [ $TRACE == 1 ]; then outputHandler "_MSG: '${_MSG}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
            
            if [[ $_JMS_TEST_DMMETHODS -ne 4 ]]; then
                # Process the error path
                outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
            else
                # Process the normal state path
                outputHandler "Java Method Server is responding properly on http://$HOSTNAME:$_JMS_PORT/DmMethods/servlet/DoMethod" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
                _ARRAY_DOCBASES[${#_ARRAY_DOCBASES[@]}]="$_docbase"
            fi
        fi
    fi

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              
