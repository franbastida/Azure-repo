jmsParseLogs () {
    if [ -z "$1" ] || [[ ! " ${SEVERITIES[@]} " =~ " $1 " ]];
    then
        echo "You need to pass severity of the alert as the first argument of the jmsParseLogs function call."
        echo "Available severities: ${SEVERITIES[@]}"
        if [ ! -z "$1" ]; then
            echo "Passed argument: $1"
        fi
        exit
    fi

    _SEVERITY="$1"
    #_SEVERITY='warning' # Available severities: warning, minor, major, critical
            
    _APPLICATION='Documentum'
    _OBJECT="JMS"

    _JMS_PATH=$(find $DM_JMS_HOME/ -name DctmServer_MethodServer -type d -printf "%h\n")
    _ERROR_PATTERN='MSG: \[[A-Za-z_]*\]'
    _DAY=$(date +%F)

    touch $SCRIPT_ROOT/logs/log_dumps/jms.log.$_DAY
    
    _LOG_FILES=(${_LOG_FILES:-`find $_JMS_PATH -iname "*.log" -type f `})
    if [ $DEBUG == 1 ]; then outputHandler "_LOG_FILES: $_LOG_FILES" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

    for _file in "${_LOG_FILES[@]}"; 
    do
        #check last entry reported
        _LAST=`grep -F "$_file" $SCRIPT_ROOT/logs/log_dumps/jms.log.$_DAY | tail -1`
        if [ $DEBUG == 1 ]; then outputHandler "${_file##*/} _LAST: $_LAST" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

        if [ "$_LAST" <> " " ];
        then
            _LASTLINENUMBER=`echo ${_LAST} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f2`
            ((_NEXTLINENUMBER=_LASTLINENUMBER+1))
            _LASTERROR=`echo ${_LAST} | grep -o "$_ERROR_PATTERN"`

            OLD_IFS="$IFS"
            IFS=$'\n'
                _ERROR_STRINGS=(${_ERROR_STRINGS:-`tail -n +${_NEXTLINENUMBER} $_file | grep -Hn "$_ERROR_PATTERN" | tr '\t' ' '`})
            IFS="$OLD_IFS"
        else
            OLD_IFS="$IFS"
            IFS=$'\n'
                _ERROR_STRINGS=(${_ERROR_STRINGS:-`grep -Hn "$_ERROR_PATTERN" $_file | tr '\t' ' '`})
            IFS="$OLD_IFS"
        fi

        for _line in "${_ERROR_STRINGS[@]}";
        do
            if [ $DEBUG == 1 ]; then outputHandler "_line: $_line" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

            _entry=`echo ${_line} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f3`
            _linenumber=`echo ${_line} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f2`
            _filename=`echo ${_line} | sed 's/:/|/g; s/|/:/3g' | cut -d '|' -f1`
            
            if [ "$_filename" = '(standard input)' ]
            then
                ((_linenumber=_LASTLINENUMBER+_linenumber))
            fi
            _error=`echo ${_line} | grep -o "$_ERROR_PATTERN"`

            _MSG="$STAGE $_error found in $_file"
            notificationHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            echo "$_file|$_linenumber|$_error" >> "$SCRIPT_ROOT/logs/log_dumps/jms.log.$_DAY"

            # Cleanup
            unset _entry
            unset _linenumber
            unset _error

        done

        # Cleanup
        unset _ERROR_STRINGS
        unset _NEXTLINENUMBER
        unset _LASTLINENUMBER
    done


    # Cleanup variables
    unset _DAY
    unset _LOG_FILES
    unset _SEVERITY
    unset _APPLICATION
    unset _OBJECT
}
