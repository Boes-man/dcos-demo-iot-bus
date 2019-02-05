#!/bin/bash

install_fastdata-iot_get_certs () {
  echo "Retrieving Cluster Certifcates for API calls"
  curl -k $(dcos config show core.dcos_url)/ca/dcos-ca.crt -o dcos-ca.crt
}

install_fastdata-iot_ee_cli () {
  echo "Install EE CLI"
  dcos package install dcos-enterprise-cli --yes
}

install_fastdata-iot_spark () {
  echo "Create Spark Service Account and Secret"
  dcos security org service-accounts keypair spark_priv.pem spark_pub.pem
  dcos security org service-accounts create -p spark_pub.pem -d "Spark service account" spark-iot
  dcos security secrets create-sa-secret --strict spark_priv.pem spark-iot spark/spark-iot
  sleep 2

  echo "Permissioning Spark Service Account"
  dcos security org users grant spark-iot dcos:mesos:master:task:user:root create
  dcos security org users grant spark-iot dcos:mesos:master:framework:role:* create
  dcos security org users grant spark-iot dcos:mesos:master:task:app_id:/spark create
  dcos security org users grant dcos_marathon dcos:mesos:master:task:user:root create
  sleep 2

  echo "Installing Spark DCOS Package"
  dcos package install spark --options=spark_strict.json --yes
  echo "Waiting for Spark install to finish"
  sleep 90
}

install_fastdata-iot_cassandra () {
  echo "Create Cassandsra Service Account and Secret"
  dcos security org service-accounts keypair cassandra_priv.pem cassandra_pub.pem
  dcos security org service-accounts create -p cassandra_pub.pem -d "Cassandra service account" cassandra-iot
  dcos security secrets create-sa-secret --strict cassandra_priv.pem cassandra-iot cassandra/cassandra-iot
  sleep 2

  echo "Permissioning Cassandra Service Account"
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:cassandra-role \
  -d '{"description":"Controls the ability of cassandra-role to register as a framework with the Mesos master"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:cassandra-role \
  -d '{"description":"Controls the ability of cassandra-role to reserve resources"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:cassandra-role \
  -d '{"description":"Controls the ability of cassandra-role to access volumes"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:cassandra-iot \
 -d '{"description":"Controls the ability of cassandra-iot to reserve resources"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:cassandra-iot \
  -d '{"description":"Controls the ability of cassandra-iot to access volumes"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:cassandra-role/users/cassandra-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:cassandra-role/users/cassandra-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:cassandra-role/users/cassandra-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/cassandra-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:cassandra-iot/users/cassandra-iot/delete
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:cassandra-iot/users/cassandra-iot/delete
  sleep 2

  echo "Installing Cassandra DCOS Package"
  dcos package install cassandra --options=cassandra_strict.json --yes
  echo "Waiting for Cassandra DCOS Nodes"
  sleep 150
  dcos job add cassandra-schema.json
  sleep 10
  dcos job run init-cassandra-schema-job
}

install_fastdata-iot_kafka () {
  echo "Create Kafka Service Account and Secret"
  dcos security org service-accounts keypair kafka_priv.pem kafka_pub.pem
  dcos security org service-accounts create -p kafka_pub.pem -d "kafka service account" kafka-iot
  dcos security secrets create-sa-secret --strict kafka_priv.pem kafka-iot kafka/kafka-iot
  sleep 2

  echo "Permissioning Kafka Service Account"
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:kafka-role \
  -d '{"description":"Controls the ability of kafka-role to register as a framework with the Mesos master"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:kafka-role \
  -d '{"description":"Controls the ability of kafka-role to reserve resources"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:kafka-role \
  -d '{"description":"Controls the ability of kafka-role to access volumes"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:kafka-iot \
  -d '{"description":"Controls the ability of kafka-iot to reserve resources"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:kafka-iot \
  -d '{"description":"Controls the ability of kafka-iot to access volumes"}' \
  -H 'Content-Type: application/json'
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:kafka-role/users/kafka-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:kafka-role/users/kafka-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:kafka-role/users/kafka-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/kafka-iot/create
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:kafka-iot/users/kafka-iot/delete
  sleep 2
  curl -X PUT --cacert dcos-ca.crt \
  -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:kafka-iot/users/kafka-iot/delete
  sleep 2

  echo "Installing Kafka DCOS Package"
  dcos package install kafka --options=kafka_strict.json --yes
  echo "Waiting for Kafka Brokers"
  sleep 90
}

install_fastdata-iot_ingest () {
  echo "Install Ingestion Akka App"
  dcos marathon app add akka-ingest.json
  sleep 120
}

install_fastdata-iot_spark_job () {
  echo "Create Spark Job"
  dcos spark run --submit-args='--conf spark.mesos.principal=spark-iot --driver-cores 0.1 --driver-memory 1024M --total-executor-cores 4 --class de.nierbeck.floating.data.stream.spark.KafkaToCassandraSparkApp https://oss.sonatype.org/content/repositories/snapshots/de/nierbeck/floating/data/spark-digest_2.11/0.2.1-SNAPSHOT/spark-digest_2.11-0.2.1-SNAPSHOT-assembly.jar METRO-Vehicles node-0-server.cassandra.autoip.dcos.thisdcos.directory:9042 broker.kafka.l4lb.thisdcos.directory:9092'
  sleep 60
}

install_fastdata-iot_frontend () {
  echo "Install Frontend App"
  dcos marathon app add dashboard.json
}

install_fastdata-iot_get_certs
install_fastdata-iot_ee_cli
install_fastdata-iot_spark
install_fastdata-iot_cassandra
install_fastdata-iot_kafka
install_fastdata-iot_ingest
install_fastdata-iot_spark_job
install_fastdata-iot_frontend
