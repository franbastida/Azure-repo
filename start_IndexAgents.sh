#!/bin/bash
SCRIPT_ROOT=$(dirname $(readlink -f $0))

# Load environment-specific variables
source "$SCRIPT_ROOT/settings/settings_$STAGE.sh"

### Main body
     _DOCBASES=(${_DOCBASES:-`ls -1 $DOCUMENTUM/dba/config/`})

    for _docbase in "${_DOCBASES[@]}";
    do
        echo "Checking IndexAgent connection for $_docbase repository - getting dm_ftindex_agent_config object"
        # Define the idql program location and connection arguments
         _IDQL="${DM_HOME}/bin/idql ${_docbase} -U${DMUSER} -P -n"
        # Run the idql query for obtaining configuration about IndexAgent for specified docbase
        _QUERY_RESULT=`timeout 60s ${_IDQL} <<_EOF_
select object_name,':',index_name from dm_ftindex_agent_config
go
_EOF_
`
        # Save the idql application exit code
         _IDQL_RETURN_CODE=$?
 
        # Run the verification if docbase is running and has IndexAgent defined
             _indexagent_index_name=${_indexagent_index_name:-`grep ftindex_01 <<< "$_QUERY_RESULT" | cut -d ':' -f2 | xargs`}
             _indexagent_object_name=${_indexagent_object_name:-`grep ftindex_01 <<< "$_QUERY_RESULT" | cut -d ':' -f1 | xargs`}

            if [ -z "$_indexagent_object_name" ];
            then
                echo ="No IndexAgent configuration found for $_docbase"
            else
                echo "Starting IndexAgent for $_docbase repository"

                # Define the iapi program location and connection arguments
                 _IAPI="timeout 60s ${DM_HOME}/bin/iapi ${_docbase} -U${DMUSER} -P"
                # Run the iapi query for obtaining configuration about IndexAgent state for specified docbase
                _IAPI_RESULT=`${_IAPI} <<_EOF_
apply,c,,FTINDEX_AGENT_ADMIN,NAME,S,${_indexagent_index_name},AGENT_INSTANCE_NAME,S,${_indexagent_object_name},ACTION,S,start
next,c,q0
dump,c,q0
close,c,q0
_EOF_
`
                echo "_IAPI_RESULT: $_IAPI_RESULT"

                unset _indexagent_index_name
                unset _indexagent_object_name
                unset _IAPI
                unset _QUERY_RESULT
                unset _IDQL_RETURN_CODE
            fi
    done

