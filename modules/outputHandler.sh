#!/bin/bash
# Print verbose output to screen and to log file

### Usage: outputHandler "$_MSG" "INFO" "$_APPLICATION" "$_OBJECT"
### Usage: if [ $DEBUG == 1 ]; then outputHandler "$_MSG" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
### Usage: if [ $TRACE == 1 ]; then outputHandler "_VARIABLE: '${_VARIABLE}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi


outputHandler () {
    local ___MSG="$1"
    local ___SEVERITY="$2"
    local ___APPLICATION="$3"
    local ___OBJECT="$4"
    local ___DAY=$(date +%F)
    local ___TIMESTAMP=${TIMESTAMP:-`date +"%Y-%m-%d %T"`}

    if [ $STDOUT == 1 ]; then 
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___MSG: '${___MSG}'"; fi
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___SEVERITY: '${___SEVERITY}'"; fi
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___APPLICATION: '${___APPLICATION}'"; fi
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___OBJECT: '${___OBJECT}'"; fi
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___DAY: '${___DAY}'"; fi
        if [ $MAX_VERBOSITY == 1 ]; then echo "$___TIMESTAMP MAX_VERBOSITY $___OBJECT outputHandler ___TIMESTAMP: '${____MSG}'"; fi
        echo "$___TIMESTAMP ${___SEVERITY^^} $EXECUTION_ID $___OBJECT $___MSG"
    fi

    echo "$___TIMESTAMP ${___SEVERITY^^} $EXECUTION_ID $___OBJECT $___MSG" >> "$SCRIPT_ROOT/logs/monitoring.log.$___DAY"

}