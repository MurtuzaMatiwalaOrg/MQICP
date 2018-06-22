#!/bin/bash
# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

stop()
{
	echo "----------------------------------------"
	echo "Stopping node $NODE_NAME..."
	mqsistop $NODE_NAME
	echo "Stopping Queue Manager $MQ_QMGR_NAME..."
	endmqm $MQ_QMGR_NAME
}
parameterCheck()
{
  : ${MQ_QMGR_NAME?"ERROR: You need to set the MQ_QMGR_NAME environment variable"}

  # We want to do parameter checking early as then we can stop and error early before it looks
  # like everything is going to be ok (when it won't)
  if [ ! -z ${MQ_TLS_KEYSTORE+x} ]; then
    if [ -z ${MQ_TLS_PASSPHRASE+x} ]; then
      echo "Error: If you supply MQ_TLS_KEYSTORE, you must supply MQ_TLS_PASSPHRASE"
      exit 1;
    fi
  fi
}
config()
{
  # Populate and update the contents of /var/mqm - this is needed for
	# bind-mounted volumes, and also to migrate data from previous versions of MQ

  setup-var-mqm.sh

  if [ -z "${MQ_DISABLE_WEB_CONSOLE}" ]; then
    echo $MQ_ADMIN_PASSWORD
    # Start the web console, if it's been installed
    which strmqweb && setup-mqm-web.sh
  fi

  ls -l /var/mqm
  source /opt/mqm/bin/setmqenv -s
  echo "----------------------------------------"
  dspmqver
  echo "----------------------------------------"

  QMGR_EXISTS=`dspmq | grep ${MQ_QMGR_NAME} > /dev/null ; echo $?`
  if [ ${QMGR_EXISTS} -ne 0 ]; then
    echo "Checking filesystem..."
    amqmfsck /var/mqm
    echo "----https://hub.jazz.net/code/edit/edit.html#/code/file/paj-OrionContent/paj%2520%257C%2520IIB-MQ-DB2/iib_manage.sh------------------------------------"
    MQ_DEV=${MQ_DEV:-"true"}
    if [ "${MQ_DEV}" == "true" ]; then
      # Turns on early adopt if we're using Developer defaults
      export AMQ_EXTRA_QM_STANZAS=Channels:ChlauthEarlyAdopt=Y
    fi
    crtmqm -q ${MQ_QMGR_NAME} || true
    if [ ${MQ_QMGR_CMDLEVEL+x} ]; then
      # Enables the specified command level, then stops the queue manager
      strmqm -e CMDLEVEL=${MQ_QMGR_CMDLEVEL} || true
    fi
    echo "----------------------------------------"
  fi
  strmqm ${MQ_QMGR_NAME}

  # Turn off script failing here because of listeners failing the script
  set +e
  for MQSC_FILE in $(ls -v /etc/mqm/*.mqsc); do
    runmqsc ${MQ_QMGR_NAME} < ${MQSC_FILE}
  done
  set -e

  echo "----------------------------------------"
  mq-dev-config.sh ${MQ_QMGR_NAME}
  echo "----------------------------------------"
}

state()
{
  dspmq -n -m ${MQ_QMGR_NAME} | awk -F '[()]' '{ print $4 }'
}

monitor()
{
	# Loop until "dspmq" says the queue manager is running
  until [ "`state`" == "RUNNING" ]; do
    sleep 1
  done
  dspmq
  echo "IBM MQ Queue Manager ${MQ_QMGR_NAME} is now fully running"
  # Loop until "dspmq" says the queue manager is not running any more
  until [ "`state`" != "RUNNING" ]; do
    sleep 5
  done
	echo "----------------------------------------"
	echo "Running - stop container to exit"
	# Loop forever by default - container must be stopped manually.
  # Here is where you can add in conditions controlling when your container will exit - e.g. check for existence of specific processes stopping or errors being reported
	while true; do
		sleep 1
	done
}
mq-license-check.sh
parameterCheck
config
trap stop SIGTERM SIGINT
monitor