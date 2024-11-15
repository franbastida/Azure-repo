#!/bin/bash
# This function takes care of communicating with Operation Manager (HP OVO)
# sending warning emails and writing information to log file

### Usage: notificationHandler "$MSG" "$SEVERITY" "$APPLICATION" "$OBJECT" "$__DETAILS" "$__STATE"

notificationHandler () {
    local ____MSG="$1"
    local ____SEVERITY="$2"
    local ____APPLICATION="$3"
    local ____OBJECT="$4"
    local ____DETAILS="$5"
    local ____STATE="$6"
    local ____DAY=$(date +%F)
    local ____TIMESTAMP=${TIMESTAMP:-`date +"%Y-%m-%d %T"`}

    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____MSG: '${____MSG}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____SEVERITY: '${____SEVERITY}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____APPLICATION: '${____APPLICATION}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____OBJECT: '${____OBJECT}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____DETAILS: '${____DETAILS}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____DAY: '${____DAY}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi
    if [ $MAX_VERBOSITY == 1 ]; then outputHandler "notificationHandler ____TIMESTAMP: '${____TIMESTAMP}'" "MAX_VERBOSITY" "$____APPLICATION" "$____OBJECT"; fi


    if [ $OPCMSG_ENABLED  == 0 ] && [ $MAIL_ENABLED == 0 ];
    then
        outputHandler "Notification sending is disabled - skipping" "INFO" "$____APPLICATION" "$____OBJECT"
    fi

    if [ $OPCMSG_ENABLED  == 1 ] && [ $____SEVERITY != "INFO" ]; 
	then
		#sendOpcmsgError($MSG, $SEVERITY, $APPLICATION, $OBJECT, $MSG_GROUP, $STAGE)
		if [ $DEBUG == 1 ]; then outputHandler "Sending opcmsg notification: $____SEVERITY '$____MSG'" "DEBUG" "$____APPLICATION" "$____OBJECT"; fi
		# Fixing HP OVO alarms correlation by removing "ERROR:" or "NORMAL:" text from msg_text - MSG_TEXT=$STAGE$(echo "$STAGE $____MSG" | sed 's/^.*NORMAL:/:/');
		if [ $____STATE == "NORMAL" ]; then
			MSG_TEXT=$STAGE$(echo "$STAGE $____MSG" | sed 's/^.*NORMAL:/:/');
			# $OV_ROOT/opcmsg severity="normal" application="$____APPLICATION" object="$____OBJECT" msg_text="$MSG_TEXT" msg_grp="$MSG_GROUP" -option stage="$STAGE" -option Description="$____DETAILS";
			if [ $TRACE == 1 ]; then 
				outputHandler "$OV_ROOT/opcmsg severity='normal' application='$____APPLICATION' object='$____OBJECT' msg_text='$MSG_TEXT' msg_grp='$MSG_GROUP' -option stage='$STAGE'" "TRACE" "$__APPLICATION" "$__OBJECT"; 
			fi
		else # STATE != "NORMAL" meaning there is an alarm
			MSG_TEXT=$STAGE$(echo "$STAGE $____MSG" | sed 's/^.*ERROR:/:/');
			# $OV_ROOT/opcmsg severity="$____SEVERITY" application="$____APPLICATION" object="$____OBJECT" msg_text="$MSG_TEXT" msg_grp="$MSG_GROUP" -option stage="$STAGE" -option Description="$____DETAILS"; 
			if [ $TRACE == 1 ]; then 
				outputHandler "$OV_ROOT/opcmsg severity='$____SEVERITY' application='$____APPLICATION' object='$____OBJECT' msg_text='$MSG_TEXT' msg_grp='$MSG_GROUP' -option stage='$STAGE'" "TRACE" "$__APPLICATION" "$__OBJECT"; 
			fi
		fi
    fi
    if [ $MAIL_ENABLED == 1 ] && [ $____SEVERITY != "INFO" ]; then
        #sendAlertMail($MAIL_SENDER, $MAIL_RECEIPIENT, $SMTP_SERVER, $MSG, $SEVERITY, $APPLICATION, $OBJECT, $STAGE)
        if [ $DEBUG == 1 ]; then outputHandler "Sending email notification: $____SEVERITY '$____MSG'" "DEBUG" "$____APPLICATION" "$____OBJECT"; fi
        local ____MAIL_BODY="$____TIMESTAMP $HOSTNAME $STAGE $____MSG $____DETAILS";
        # mailx -v -r "$MAIL_SENDER" -s "[HP OVO] $STAGE $HOSTNAME $____SEVERITY $____MSG" -S smtp="$SMTP_SERVER" $MAIL_RECEIPIENT <<< $____MAIL_BODY;
        if [ $TRACE == 1 ]; then outputHandler "echo '$____TIMESTAMP $HOSTNAME $STAGE $____MSG $____DETAILS' | mailx -v -r '$MAIL_SENDER' -s '[HP OVO] $STAGE $HOSTNAME $____SEVERITY $____APPLICATION $____OBJECT' -S smtp='$SMTP_SERVER' $MAIL_RECEIPIENT" "TRACE" "$__APPLICATION" "$__OBJECT"; fi
    fi
}

