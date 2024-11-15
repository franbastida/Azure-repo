#!/bin/bash
# Monitor the status of Brava Publisher
# Function takes 3 required parameters:
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: bravaPublisherProcess ()
### Example: bravaPublisherProcess rcNormal rcError "SEVERITY[warning]"

bravaPublisherProcess () {
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
   
    # Identify if the process is running
    local _publisherStatus=$(/www/opentext/publisher/bin/publisher status)
    ### Error handling block
    local _MSG="Brava Publisher is not in STARTED state"

    if [[ $_publisherStatus ==  *"Wrapper:STARTED, Java:STARTED" ]]; 
    then  # Process the NORMAL state path
       outputHandler "Brava Publisher is correctly STARTED" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
       _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
    else
      outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
      _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
    fi

    unset _MSG

    ######################################################################
    # Returning results
    eval $_RESULTVAR_NORMAL="\"NORMAL[${_ARRAY_NORMAL[*]}]\""
    eval $_RESULTVAR_ERROR="\"ERROR[${_ARRAY_ERROR[*]}]\""
    # Return dditional arrays values (if needed)
    #eval $_RESULTVAR_ADDITIONAL="\"${_ARRAY_ADDITIONAL[*]}\""
    ### Variable cleanup for inputParameterHandler function
    inputParameterHandlerCleaner
}