#!/bin/bash
# Using Nagios tool check_tcp test connectivity performance from Tomcat to Content Servers
# Function takes 3 required parameters:
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: networkCheckWebapp ()
### Example: networkCheckWebapp rcNormal rcError "SEVERITY[warning]"
### Example - override list of tomcats: networkCheckWebapp rcNormal rcError "SEVERITY[$_SEVERITY]" "$TOMCAT_LIST"

# Nagios chech_tcp Usage:
#    check_tcp -H host -p port [-w <warning time seconds>] [-c <critical time seconds>]
#    Place check_tcp in $SCRIPT_ROOT

networkCheckWebapp () {
### Setting required initial variables and calculating values from input parameters
    local _RESULTVAR_NORMAL=$1
    local _RESULTVAR_ERROR=$2
    # Additional arrays (if needed)
    # local _RESULTVAR_ADDITIONAL=$3

    local _ARRAY_NORMAL=()
    local _ARRAY_ERROR=()
    # Additional arrays (if needed)
    # local _RESULTVAR_ADDITIONAL=()

    inputParameterHandler "$@"
######################################################################

    ### Main body
    local _TOMCAT=$(find $TOMCAT_ROOT/ -maxdepth 1 -name "tomcat*" | head -1);
    local _DFC=(${_DFCs:-$(find $_TOMCAT -name "dfc.properties" | head -1)})
    local _CS_STRING=(${_CS_STRING:-$(grep dfc.docbroker.host $_DFC | cut -d '=' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')})
    local _CS_PORT=$(grep dfc.docbroker.port $_DFC | cut -d '=' -f2 | head -1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    local _MSG="Nagios check_tcp fail on ${HOSTNAME} connecting to Content Server"
    local _FILE=$SCRIPT_ROOT/check_tcp
    
    if [[ -x $_FILE ]]  # File check_tcp exists and is executable
    then
        for _cs in "${_CS_STRING[@]}";
        do
        outputHandler "Running Nagios check_tcp test for $_cs:$_CS_PORT" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                    
        local _check_tcp_result=$($SCRIPT_ROOT/check_tcp -H $_cs -p $_CS_PORT -w 1 -c 5)
        local _check_tcp_return_code=$(echo $_check_tcp_result | cut -d "-" -f 1)
        

        if [ "$_check_tcp_return_code" != "TCP OK " ]; then  # Process with the error
            outputHandler "$_MSG $_cs on port $_CS_PORT" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG $_cs:$_CS_PORT|" # Add error to array with errors
        else # Process the normal state path
            outputHandler "Nagios check_tcp SUCCESFULLY on ${HOSTNAME} connecting to Content Server $_cs on port $_CS_PORT" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG $_cs:$_CS_PORT|" # Add error to array with items without error
        fi

        done
    else
        outputHandler "File '$_FILE' is not executable or found" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
    fi
    
    unset _TOMCAT _DFC _DFC _CS_STRING _CS_PORT _cs _check_tcp_result _check_tcp_return_code _FILE
    unset _MSG _SEVERITY _APPLICATION _OBJECT # Clean up variables


######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    # Return dditional arrays values (if needed)
    #eval $_RESULTVAR_ADDITIONAL="\"${_ARRAY_ADDITIONAL[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}