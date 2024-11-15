#!/bin/bash
# Check the http response of applications configured in httpd vhost settings
# Function takes 3 required parameters: 
# $1 for storing list of items with no error reported
# $2 for storing list of items with error reported
# SEVERITY[level] for proper level being written to host

### Usage: httpdVhostResponse ()
### Example: functionName rcNormal rcError "SEVERITY[warning]"
### Example - provide all optional parameters - httpdVhostResponse rcNormal rcError "SEVERITY[$_SEVERITY]" "$TOMCAT_LIST" "$WEBAPPS_LIST" "$ENDPOINT_LIST"



httpdVhostResponse () {
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
    # List all vhosts configuration files
    local _httpd_conf_files=(${_httpd_conf_files=`find /etc/apache2/vhosts.d/ -name "$HTTPD_CONF_FILES_MASK"`})
    if [ $TRACE == 1 ]; then outputHandler "_httpd_conf_files[*]: '${_httpd_conf_files[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    for _httpd_conf_file in "${_httpd_conf_files[@]}";
    do
		outputHandler "Testing for $_httpd_conf_file vhost file" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
        # Get the vhost dns connection name
        local _httpd_conf_vhost=`grep "<VirtualHost" $_httpd_conf_file | cut -d " " -f 2 | cut -d ":" -f 1 | uniq`
        if [ $DEBUG == 1 ]; then outputHandler "_httpd_conf_vhost: $_httpd_conf_vhost" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        # Get list of all of applications configured for specified vhost
        local _jkmount_webapps=(${_jkmount_webapps=`grep JkMount $_httpd_conf_file | grep -v "[#*]" | cut -d "/" -f 2 | cut -d " " -f 1 | cut -f 1 | uniq`})
        if [ $DEBUG == 1 ]; then outputHandler "_jkmount_webapps[*]: '${_jkmount_webapps[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        for _app in "${_jkmount_webapps[@]}";
        do
            if [[ " ${_WEBAPPS[@]} " =~ " $_app " ]] || [ ${#_WEBAPPS[@]} -eq 0 ];
            then
                # Identify the endpoint used for a healthcheck - use root application name in standard cases
                local _endpoint="$_app"
                # Override healthcheck endpoint based on the configuration
                for i in "${_ENDPOINTS[@]}"
                do
                    local _app_name=`echo $i | cut -d "|" -f 1`
                    if [ "$_app_name" == "$_app" ] ; then
                        _endpoint=`echo $i | cut -d "|" -f 2`
                    fi
                    unset _app_name
                done

                # Run the healthcheck
                local _curl_result=`curl -ILs -X GET http://$_httpd_conf_vhost/$_endpoint --insecure | grep HTTP | tail -1`
                if [ $TRACE == 1 ]; then outputHandler "_curl_result: $_curl_result" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
                local _curl_return_code=`echo $_curl_result | cut -d " " -f 2`
                if [ $DEBUG == 1 ]; then outputHandler "_curl_return_code: $_curl_return_code" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

                ### Error handling block
                local _MSG="Incorrect http response for http://$_httpd_conf_vhost/$_endpoint"
                if [[ $_curl_return_code -ne 200 ]]; # condition to determine error
                then # Process the error path
                    outputHandler "$_MSG - code $_curl_return_code" "$_SEVERITY" "$_APPLICATION" "$_OBJECT" # Echo error message to logs/output
                    _ARRAY_ERROR[${#_ARRAY_ERROR[@]}]="$_MSG|" # Add error to array with errors
                else # Process the normal state path
                    outputHandler "http://$_httpd_conf_vhost/$_endpoint responded with 200 return code" "INFO" "$_APPLICATION" "$_OBJECT"  # Echo info message to logs/output
                    _ARRAY_NORMAL[${#_ARRAY_NORMAL[@]}]="$_MSG|" # Add error to array with items without error
                    # Process additional arrays
                    # _ARRAY_ADDITIONAL[${#_ARRAY_ADDITIONAL[@]}]="$_port"
                fi
                unset _MSG
                unset _curl_result
                unset _curl_return_code
                unset _endpoint
            fi
        done
		unset _httpd_conf_vhost
		unset _jkmount_webapps
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
                                                                                                                                                                                              

