#!/bin/bash
# Count the processes for repositories on host
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: functionName ()
### Example: functionName rcNormal rcError "SEVERITY[warning]"
### Example - override additional array: functionName rcNormal rcError "SEVERITY[warning]" "DOCBASES[develop Engineering]"


functionName () {
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

    ### Error handling block
    local _MSG="Define the error"

    if [[ 1 -ne 0 ]]; # condition to determine error
    then # Process the error path
        outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
        _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
    else # Process the normal state path
        outputHandler "Successful execution" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
        _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
        # Process additional arrays
        # _ARRAY_ADDITIONAL[${#_ARRAY_ADDITIONAL[@]}]="$_port"
    fi
        
######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    # Return dditional arrays values (if needed)
    #eval $_RESULTVAR_ADDITIONAL="\"${_ARRAY_ADDITIONAL[*]}\""

    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}
                                                                                                                                                                                              