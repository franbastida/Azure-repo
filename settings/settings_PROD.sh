#!/bin/bash

# Environment settings
MSG_GROUP='Documentum'
MAIL_SENDER='documentum-alarms@basf.com'
MAIL_RECEIPIENT='is-documentum-hosting@basf.com'
SMTP_SERVER='smtpout.basf.net'
HOSTNAME=${HOSTNAME:-`hostname`}
HOSTNAME_FQDN=${HOSTNAME_FQDN:-`hostname -f`}
DMUSER=${DMUSER:-`whoami`}

# Environment settings - Tomcat
TOMCAT_USER='wwwrun'
TOMCAT_ROOT='/www'

# Environment settings - Apache httpd
HTTPD_ROOT="/etc/apache2"
HTTPD_CONF_FILES_MASK="*documentum.basf.net.conf"

# Settings required for running the script
SCRIPT_ROOT=$(dirname $(readlink -f $0))
SCRIPT_ROOT="$(dirname "$SCRIPT_ROOT")"
OV_ROOT='/opt/OV/bin' # path to opcmsg tool directory

# Create required folder structure
mkdir -p ${SCRIPT_ROOT}/logs/log_dumps
mkdir -p ${SCRIPT_ROOT}/status_files/

# List of available alert severities
SEVERITIES=('warning' 'minor' 'major' 'critical')
