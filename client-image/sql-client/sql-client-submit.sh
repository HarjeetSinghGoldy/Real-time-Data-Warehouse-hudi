#!/bin/bash

${FLINK_HOME}/bin/sql-client.sh embedded -d ${FLINK_HOME}/conf/sql-client-conf.yaml -l /opt/flink/lib,/opt/flink/plugins