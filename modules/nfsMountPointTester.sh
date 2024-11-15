#!/bin/bash
# Check that Documentum server mount point vg01lv02 is available
# Function takes 3 required parameters:
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: nfsMountPointTester ()
### Example: functionName rcNormal rcError "SEVERITY[warning]"
### Example - provide all optional parameters - httpdVhostResponse rcNormal rcError "SEVERITY[$_SEVERITY]" "$TOMCAT_LIST" "$WEBAPPS_LIST" "$ENDPOINT_LIST"

# Set up NFS folder
_NFS="/vg01lv02";
is_mounted_nfs_return="NULL";


is_mounted_nfs() {
    mount | awk -v DIR="$_NFS" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}';
	is_mounted_nfs_return=$?;
}

nfsMountPointTester () {
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
	
	local _MSG="Documentum NFS Folder '$_NFS'"
######################################################################


### Main body
    # List all vhosts configuration files
    
    if [ $TRACE == 1 ]; then outputHandler "Checking NFS mount point" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    outputHandler "Testing Documentum NFS mount point" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output

    # Run the healthcheck - condition to determine error	
	is_mounted_nfs;
	if [ $is_mounted_nfs_return == "255" ]; 
    then # Process the ERROR path
	  outputHandler "ERROR on '$_MSG'" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"; # Echo error message to logs/output
      _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|"; # Add error to array with errors
    else # Process the NORMAL state path
	  outputHandler "SUCCESFULLY mounted '$_MSG'" "INFO" "$_APPLICATION" "$_OBJECT"; # Echo info message to logs/output
      _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|"; # Add error to array with items without error
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
