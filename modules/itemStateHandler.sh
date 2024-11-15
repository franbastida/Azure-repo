#!/bin/bash
# This function takes care of manipulating

### Usage: itemStateHandler "$ITEMID" "$SEVERITY" "$MESSAGE" "$STATE" "$_APPLICATION" "$_OBJECT" "$_DETAILS"
### Example: itemStateHandler "docbroker_Engineering_unavailable" "$_SEVERITY" "Error: Docbroker on $_port has no '${_docbase}' registered" "ERROR" "Documentum" "docbase" "http://confluence"
### Example: itemStateHandler "docbroker_Engineering_unavailable" "$_SEVERITY" "Error: Docbroker on $_port has no '${_docbase}' registered" "NORMAL" "Documentum" "docbase" "http://confluence"


itemStateHandler () {
    local OLD_IFS="$IFS"
    IFS=$'|'


    # Setting required variables
    local __ITEMID="$1"
    local __SEVERITY="$2"
    local __MESSAGES="$3"
    __MESSAGES=${__MESSAGES#*\[}   # remove prefix ending in "["
    __MESSAGES=(${__MESSAGES%\]*})   # remove suffix starting with "]"
    local __STATE=`echo "$3" | cut -d "[" -f 1`
    local __APPLICATION="$4"
    local __OBJECT="$5"
    local __DETAILS="$6"
    local __MONTH=$(date +%Y-%m)
    local __DAY=$(date +%F)
    local __TIMESTAMP=${TIMESTAMP:-`date +"%Y-%m-%d %T"`}
    #local __STATUS_FILE="${SCRIPT_ROOT}/status_files/${CALLER_SCRIPT_NAME}.status"
    local __STATUS_FILE="${SCRIPT_ROOT}/status_files/status"
    local __HISTORY_FILE="${SCRIPT_ROOT}/status_files/status_history.$__MONTH"

    # Create file header if file does not exist
    if [[ ! -f $__STATUS_FILE ]]; then
        echo "ITEMID;SEVERITY;MESSAGE;STAGE;SERVER;STATE;COUNT" > $__STATUS_FILE
    fi

    for __MESSAGE in ${__MESSAGES[@]}; do
        # Check if the entry already exists and has current status
        __MESSAGE="$(echo -e "${__MESSAGE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # Trim the item
        local __LINE=`grep -FHn "${__ITEMID};${__SEVERITY};${__MESSAGE};${STAGE};${HOSTNAME}" $__STATUS_FILE`
        local __entry=`echo ${__LINE} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f3`
        local __linenumber=`echo ${__LINE} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f2`
        local __filename=`echo ${__LINE} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f1`

        local __count=`echo ${__entry} | cut -d ';' -f7`
        local __state=`echo ${__entry} | cut -d ';' -f6`

        if [ $TRACE == 1 ]; then outputHandler "itemStateHandler __LINE: $__LINE" "TRACE" "$__APPLICATION" "$__OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "itemStateHandler __entry: $__entry" "TRACE" "$__APPLICATION" "$__OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "itemStateHandler __linenumber: $__linenumber" "TRACE" "$__APPLICATION" "$__OBJECT"; fi
        if [ $TRACE == 1 ]; then outputHandler "itemStateHandler __filename: $__filename" "TRACE" "$__APPLICATION" "$__OBJECT"; fi

        # 1. doesn't exist - add and send notification
        if [ -z "$__LINE" ]; then
            outputHandler "Sending notification and adding entry: $__STATE '$__MESSAGE' for $__ITEMID to $__STATUS_FILE" "INFO" "$__APPLICATION" "$_OBJECT";
            echo "${__ITEMID};${__SEVERITY};${__MESSAGE};${STAGE};${HOSTNAME};${__STATE};1" >> $__STATUS_FILE
            echo "$__TIMESTAMP ${__SEVERITY^^} $EXECUTION_ID $__OBJECT ${__STATE}: $__MESSAGE" >> $__HISTORY_FILE
            notificationHandler "${__STATE}: $__MESSAGE" "$__SEVERITY" "$__APPLICATION" "$__OBJECT" "$__DETAILS" "${__STATE}"

        fi
        # 2. exists in different status - swap and send notification
        if [ ! -z "$__LINE" ] && [ "$__state" != "$__STATE" ]; then
            outputHandler "Sending notification and changing entry status: $__STATE '$__MESSAGE' for $__ITEMID to $__STATUS_FILE" "INFO" "$__APPLICATION" "$_OBJECT";
            sed -i "${__linenumber}s^.*^${__ITEMID};${__SEVERITY};${__MESSAGE};${STAGE};${HOSTNAME};${__STATE};1^" $__STATUS_FILE
            echo "$__TIMESTAMP ${__SEVERITY^^} $EXECUTION_ID $__OBJECT ${__STATE}: $__MESSAGE" >> $__HISTORY_FILE
            notificationHandler "${__STATE}: $__MESSAGE" "$__SEVERITY" "$__APPLICATION" "$__OBJECT" "$__DETAILS" "${__STATE}"
        fi
        # 3. exists in current status - skip notification
        if [ ! -z "$__LINE" ] && [ "$__state" == "$__STATE" ]; then
            outputHandler "Notification for $__MESSAGE was already sent, skipping" "INFO" "$_APPLICATION" "$_OBJECT"
            if [ $DEBUG == 1 ]; then outputHandler "Entry already exists: $__STATE '$__MESSAGE' for $__ITEMID in $__STATUS_FILE" "DEBUG" "$__APPLICATION" "$_OBJECT"; fi
            __count=$(($__count + 1))
            sed -i "${__linenumber}s^.*^${__ITEMID};${__SEVERITY};${__MESSAGE};${STAGE};${HOSTNAME};${__STATE};${__count}^" $__STATUS_FILE
        fi
    done
    IFS="$OLD_IFS"
}
