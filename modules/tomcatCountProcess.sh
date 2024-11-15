#!/bin/bash
# Count the processes for tomcat application servers on host
# Function takes 3 required parameters:
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: tomcatCountProcess ()
### Example: tomcatCountProcess rcNormal rcError "SEVERITY[warning]"
### Example - override list of tomcats: tomcatCountProcess rcNormal rcError "SEVERITY[$_SEVERITY]" "$TOMCAT_LIST"

tomcatCountProcess () {
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
    if [ ${#_TOMCATS[@]} -eq 0 ]; then
        # Get list of all tomcats on the server if not specified in configuration
        _TOMCATS=(${_TOMCATS:-`find $TOMCAT_ROOT/ -maxdepth 1 -name "tomcat*" -printf "%f\n"`})
    fi
    if [ $DEBUG == 1 ]; then outputHandler "_TOMCATS: '${_TOMCATS[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

    for _tomcat in "${_TOMCATS[@]}";
    do
        outputHandler "Running test for $_tomcat" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
        # count number of processes that match the tomcat name
        local _tomcat_proc_count=${_tomcat_proc_count:-`ps -fu $TOMCAT_USER | grep java | grep "$_tomcat" | grep -v grep | wc -l`}
        if [ $DEBUG == 1 ]; then outputHandler "_tomcat_proc_count for $_tomcat: $_tomcat_proc_count" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        ### Error handling block
        local _MSG="No processes found for $_tomcat"
        if [[ $_tomcat_proc_count -eq 0 ]]; # condition to determine error
        then # Process the error path
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else # Process the normal state path
            outputHandler "$_tomcat_proc_count processes found for $_tomcat" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
            _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
            # Process additional arrays
            # _ARRAY_ADDITIONAL[${#_ARRAY_ADDITIONAL[@]}]="$_port"
        fi
                unset _tomcat_proc_count
                unset _MSG
    done

######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    # Return dditional arrays values (if needed)
    #eval $_RESULTVAR_ADDITIONAL="\"${_ARRAY_ADDITIONAL[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}