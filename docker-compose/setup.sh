#!/bin/bash

set -uo pipefail

ELASTICSEARCH="http://elasticsearch:9200"
KIBANA="http://kibana:5601"

# Wait for Elasticsearch to start up before continuing
until $(curl --output /dev/null --silent $ELASTICSEARCH/_cat/health)
do
  echo Waiting for $ELASTICSEARCH/_cat/health
  sleep 5
done

# Create an index template
curl -f -XPUT -H "Content-Type: application/json" "$ELASTICSEARCH/_template/general" \
  -d '{ "index_patterns": ["*"], "settings": { "number_of_shards": 1, "number_of_replicas": 0 } }'

# Wait for Kibana to start up before continuing
until $(curl --output /dev/null --silent $KIBANA)
do
  echo Waiting for $KIBANA
  sleep 5
done

# Sleep an extra 10s to avoid the "Kibana server is not ready yet" error
sleep 10

# Create the index patterns. For some reason the first request always fails, so send a foo for that
for PATTERN in "foo" "parse" "send" "structure" "docker"
do
  echo $PATTERN
  curl -XPOST -H "Content-Type: application/json" -H "kbn-xsrf: kibana" --silent \
    "$KIBANA/api/saved_objects/index-pattern/$PATTERN" \
    -d '{ "attributes": { "title": "'$PATTERN'", "timeFieldName": "@timestamp" } }'
done

# Make parse the default index
curl -XPOST -H "Content-Type: application/json" -H "kbn-xsrf: kibana" --silent \
  "$KIBANA/api/kibana/settings/defaultIndex" \
  -d '{ "value": "parse" }'