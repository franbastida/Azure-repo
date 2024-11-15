#!/bin/bash
# Count the processes for repositories on host
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: databaseTestConnection ()
### Example: functionName rcNormal rcError "SEVERITY[warning]"
### Example - override additional array: functionName rcNormal rcError "SEVERITY[warning]" "DOCBASES[develop Engineering]"


databaseTestConnection () {
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
    if [ ${#_DOCBASES[@]} -eq 0 ]; then
        # Get list of all docbases on the server
        _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
    fi

    if [ -z "$_SCOPE" ]; then
        # set scope to local - try to connect to the local repository instance
        _SCOPE="global"
    fi

    for _docbase in "${_DOCBASES[@]}";
    do
        if [ $DEBUG == 1 ]; then outputHandler "Checking database connection for $_docbase repository - tnsping" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        # Get the DB connection string
        local _DB_CONN=`grep database_conn $DOCUMENTUM/dba/config/$_docbase/server.ini | cut -d '=' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
        #using global variable to enable exit code capture
        _TNSPING_RESULT=`tnsping $_DB_CONN`
        local _TNSPING_RETURN_CODE=$?
        if [ $TRACE == 1 ]; then outputHandler "_DB_CONN: $_DB_CONN" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_TNSPING_RESULT: $_TNSPING_RESULT" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "_TNSPING_RETURN_CODE: $_TNSPING_RETURN_CODE" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
        ### Error handling block
        local _MSG="Error connecting to $_DB_CONN for $_docbase"

        if [[ $_TNSPING_RETURN_CODE -ne 0 ]]; # condition to determine error
        then
            outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
            outputHandler "_TNSPING_RETURN_CODE: $_TNSPING_RETURN_CODE" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            outputHandler "_TNSPING_RESULT: $_TNSPING_RESULT" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
        else # Process the normal state path
            if [ $DEBUG == 1 ]; then outputHandler "Checking database connection for $_docbase repository - dmdbtest" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
            _DMDBTEST_RESULT=`dmdbtest -docbase_name $_docbase -init_file $DOCUMENTUM/dba/config/$_docbase/server.ini -Mconnect`
            local _DMDBTEST_RETURN_CODE=$?

            if [[ $_DMDBTEST_RETURN_CODE -ne 0 ]]; # condition to determine error
            then # Process the error path
                outputHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                outputHandler "_DMDBTEST_RETURN_CODE: $_DMDBTEST_RETURN_CODE" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
                outputHandler "_DMDBTEST_RESULT: $_DMDBTEST_RESULT" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
                _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
            else
                outputHandler "Successful connection to $_DB_CONN for $_docbase" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
                # Process additional arrays
                # _ARRAY_ADDITIONAL[${#_ARRAY_ADDITIONAL[@]}]="$_port"
            fi
        fi
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
                                                                                                                                                                                              
