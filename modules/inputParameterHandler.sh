#!/bin/bash
# Translate input parameters to enable override of default loading mechanisms 

### Usage: inputParameterHandler "$@"

inputParameterHandler () {
    for parameter in "$@"
        do
        ### Get docbases if provided in function call
        if [[ "$parameter" == "SEVERITY"* ]]; then
            _SEVERITY="$parameter"
            _SEVERITY=${_SEVERITY#*\[}   # remove prefix ending in "_"
            _SEVERITY=${_SEVERITY%\]*}   # remove suffix starting with "_"
        fi

        ### Get docbases if provided in function call
        if [[ "$parameter" == "DOCBASES"* ]]; then
            _DOCBASES="$parameter"
            _DOCBASES=${_DOCBASES#*\[}   # remove prefix ending in "_"
            _DOCBASES=(${_DOCBASES%\]*})   # remove suffix starting with "_"
        fi

        ### Get docbrokers if provided in function call
        if [[ "$parameter" == "DOCBROKERS"* ]]; then
            _DOCBROKERS="$parameter"
            _DOCBROKERS=${_DOCBROKERS#*\[}   # remove prefix ending in "_"
            _DOCBROKERS=(${_DOCBROKERS//\[})   # remove suffix starting with "_"
        fi

        ### Get docbrokers native ports list if provided in function call
        if [[ "$parameter" == "DOCBROKER_PORTS_NATIVE"* ]]; then
            _DOCBROKER_PORTS_NATIVE="$parameter"
            _DOCBROKER_PORTS_NATIVE=${_DOCBROKER_PORTS_NATIVE#*\[}   # remove prefix ending in "_"
            _DOCBROKER_PORTS_NATIVE=(${_DOCBROKER_PORTS_NATIVE%\]*})   # remove suffix starting with "_"
        fi

        ### Get the target server (global - no specific server specified, local - target the server that the script is running on)
        if [[ "$parameter" == "SCOPE"* ]]; then
            _SCOPE="$parameter"
            _SCOPE=${_SCOPE#*\[}   # remove prefix ending in "_"
            _SCOPE=${_SCOPE%\]*}   # remove suffix starting with "_"
        fi

        ### Get list of tomcat application servers from the variable
        if [[ "$parameter" == "TOMCATS"* ]]; then
            _TOMCATS="$parameter"
            _TOMCATS=${_TOMCATS#*\[}   # remove prefix ending in "_"
            _TOMCATS=${_TOMCATS%\]*}   # remove suffix starting with "_"
        fi

        ### Get list of web application deployed on tomcat server
        if [[ "$parameter" == "WEBAPPS"* ]]; then
            _WEBAPPS="$parameter"
            _WEBAPPS=${_WEBAPPS#*\[}   # remove prefix ending in "_"
            _WEBAPPS=${_WEBAPPS%\]*}   # remove suffix starting with "_"
        fi

        ### Get list of non-root endpoints for application healthcheck
        if [[ "$parameter" == "ENDPOINTS"* ]]; then
            _ENDPOINTS="$parameter"
            _ENDPOINTS=${_ENDPOINTS#*\[}   # remove prefix ending in "_"
            _ENDPOINTS=${_ENDPOINTS%\]*}   # remove suffix starting with "_"
        fi
    done

    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _SEVERITY: '${_SEVERITY}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _SCOPE: '${_SCOPE}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _DOCBASES[*]: '${_DOCBASES[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _DOCBROKERS[*]: '${_DOCBROKERS[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _DOCBROKER_PORTS_NATIVE[*]: '${_DOCBROKER_PORTS_NATIVE[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _TOMCATS[*]: '${_TOMCATS[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _WEBAPPS[*]: '${_WEBAPPS[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi
    if [ $TRACE == 1 ]; then outputHandler "inputParameterHandler _ENDPOINTS[*]: '${_ENDPOINTS[*]}'" "TRACE" "$_APPLICATION" "$_OBJECT"; fi

    # Severity check:
    if [ -z "$_SEVERITY" ] || [[ ! " ${SEVERITIES[@]} " =~ " $_SEVERITY " ]];
    then
        echo "You need to pass severity of the alert as the first argument of the docbaseCountProcess function call."
        echo "Available severities: ${SEVERITIES[@]}"
        if [ ! -z "$1" ]; then
            echo "Passed argument: $_SEVERITY"
        fi
        exit
    fi
}

# Function for cleaning up parameters loaded by inputParameterHandler
inputParameterHandlerCleaner () {
	unset _DOCBASES
    unset _DOCBROKERS
    unset _DOCBROKER_PORTS_NATIVE
    unset _SCOPE
    unset _TOMCATS
    unset _WEBAPPS
    unset _ENDPOINTS
}
