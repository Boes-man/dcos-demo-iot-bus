#!/bin/bash

dcos package uninstall kafka --yes
dcos package uninstall cassandra --yes
dcos job remove init-cassandra-schema-job
dcos package uninstall spark --yes
dcos marathon app remove /bus-demo/dashboard
dcos marathon app remove /bus-demo/ingest
dcos marathon group remove bus-demo
echo "Waiting for frameworks to cleanup"
sleep 120
dcos security secrets delete spark/spark-iot
dcos security secrets delete cassandra/cassandra-iot
dcos security secrets delete kafka/kafka-iot
dcos security org service-accounts delete spark-iot
dcos security org service-accounts delete cassandra-iot
dcos security org service-accounts delete kafka-iot
echo "Uninstall complete"
