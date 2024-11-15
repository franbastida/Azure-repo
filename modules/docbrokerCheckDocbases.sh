#!/bin/bash
docbrokerCheckDocbases () {
    if [ -z "$1" ] || [[ ! " ${SEVERITIES[@]} " =~ " $1 " ]];
    then
        echo "You need to pass severity of the alert as the first argument of the docbrokerCheckDocbases function call."
        echo "Available severities: ${SEVERITIES[@]}"
        if [ ! -z "$1" ]; then
            echo "Passed argument: $1"
        fi
        exit
    fi
    
    _SEVERITY="$1"
    #_SEVERITY='warning' # Available severities: warning, minor, major, critical
        
    _APPLICATION='Documentum'
    _OBJECT="docbroker"
    _DOCBROKER_PORTS_NATIVE=(${_DOCBROKER_PORTS_NATIVE:-`cat $DOCUMENTUM/dba/dm_documentum_config.txt | grep PORT | cut -d '=' -f2`})
    _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})
	if [ $DEBUG == 1 ]; then outputHandler "_DOCBROKER_PORTS_NATIVE: '${_DOCBROKER_PORTS_NATIVE[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi

    for _port in "${_DOCBROKER_PORTS_NATIVE[@]}"
    do
        # Get list of docbases registered in docbroker
        _DOCBASES=(${_DOCBASES:-`dmqdocbroker -t $HOSTNAME -p $_port -c getdocbasemap | grep "Docbase name" | awk 'NF>1{print $NF}'`})
        if [ $DEBUG == 1 ]; then outputHandler "_DOCBASES on docbroker port $_port: '${_DOCBASES[*]}'" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        if [ $DEBUG == 1 ]; then outputHandler "_DOCBASES length: ${#_DOCBASES[@]}" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
        # If no docbases were registered - skip checking each docbase from $DOCUMENTUM/dba/dm_documentum_config.txt
        if [ ${#_DOCBASES[@]} -lt 1 ]; 
        then
            _MSG="Error: Docbroker on $_port has no docbases registered"
            #if [ $DEBUG == 1 ]; then outputHandler "$_MSG" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
            #notificationHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
            itemStateHandler "docbrokerCheckDocbases" "$_SEVERITY" "$_MSG" "ERROR" 

        # Check each docbase from $DOCUMENTUM/dba/dm_documentum_config.txt
        else
            outputHandler "Docbases registered on docbroker port $_port: '${_DOCBASES[*]}'" "INFO" "$_APPLICATION" "$_OBJECT"
            
            # Checking if there are repositories included in $DOCUMENTUM/dba/dm_documentum_config.txt that are not registered in docbroker
            for _docbase in "${_DOCBASES[@]}";
            do
                if [ $DEBUG == 1 ]; then outputHandler "Checking if '$_docbase' is registered on docbroker on port $_port" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
                if [[ ! " ${_DOCBASES[@]} " =~ " ${_docbase} " ]]; 
                then
                    _MSG="$STAGE Error: Docbroker on $_port has no '${_docbase}' registered"
                    #if [ $DEBUG == 1 ]; then outputHandler "$_MSG" "DEBUG" "$_APPLICATION" "$_OBJECT"; fi
                    notificationHandler "$_MSG" "$_SEVERITY" "$_APPLICATION" "$_OBJECT"
                fi
            done
        fi
        unset _DOCBASES
    done
	
	unset _DOCBASES
    unset _DOCBROKER_PORTS_NATIVE
    unset _MSG
    unset _SEVERITY
    unset _APPLICATION
    unset _OBJECT
}