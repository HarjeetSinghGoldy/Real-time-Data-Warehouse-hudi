#!/bin/bash

${FLINK_HOME}/bin/sql-client.sh embedded -d ${FLINK_HOME}/conf/sql-client-conf.yaml -d ${FLINK_HOME}/opt/sql-client/exec.sql


