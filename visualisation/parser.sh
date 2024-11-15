#!/bin/bash
source $(dirname $(readlink -f $0))/../settings/settings_${STAGE}.sh
if [ -f "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh" ]; then
    source "$SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
    echo "loaded host specific configuration: $SCRIPT_ROOT/settings/settings_${STAGE}_${HOSTNAME}.sh"
fi

header=1
table_body=()
#rm -f "$DOCUMENTUM_LOGS_DIR/status.html"
rm -f "$SCRIPT_ROOT/visualisation/status.html"
cp "$SCRIPT_ROOT/visualisation/template.html" "$SCRIPT_ROOT/visualisation/status.html"
date=`date '+%Y-%m-%d %H:%M:%S'`
sed -i "s/Generated on date/Generated on $date/g" "$SCRIPT_ROOT/visualisation/status.html"
while read p; do
    if [ $header == 1 ]; then
        header=0
        continue
    fi
    while IFS=';' read -ra ADDR; do
        if [ "${ADDR[5],,}" == 'error' ]; then
            echo "<tr class='item-${ADDR[5],,}'><td>${ADDR[0]}</td><td>${ADDR[1]}</td><td>${ADDR[2]}</td><td>${ADDR[3]}</td><td>${ADDR[4]}</td><td>${ADDR[5]}</td><td>${ADDR[6]}</td></tr>" >> "$SCRIPT_ROOT/visualisation/status.html"
        fi
    done <<< $p

    
done <"$SCRIPT_ROOT/status_files/status"

header=1
while read p; do
    if [ $header == 1 ]; then
        header=0
        continue
    fi
    while IFS=';' read -ra ADDR; do
        if [ "${ADDR[5],,}" != 'error' ]; then
            echo "<tr class='item-${ADDR[5],,}'><td>${ADDR[0]}</td><td>${ADDR[1]}</td><td>${ADDR[2]}</td><td>${ADDR[3]}</td><td>${ADDR[4]}</td><td>${ADDR[5]}</td><td>${ADDR[6]}</td></tr>" >> "$SCRIPT_ROOT/visualisation/status.html"
        fi
    done <<< $p
done <"$SCRIPT_ROOT/status_files/status"

echo "</tbody></table></body></html>" >> "$SCRIPT_ROOT/visualisation/status.html"
chmod o+r "$SCRIPT_ROOT/visualisation/status.html"
#cat "$SCRIPT_ROOT/visualisation/status.html" > "$DOCUMENTUM_LOGS_DIR/status.html"
#chmod +r "$DOCUMENTUM_LOGS_DIR/status.html"
