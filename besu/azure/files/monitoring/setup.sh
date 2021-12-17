#!/bin/bash

AZURE_LOCATION=$1
LOGIN_USER=$2
SUBSCRIPTION_ID=$3

# logrotate
# 65534 & 472 are the respective container user:group pairs
mkdir -p /var/log/prometheus/ && chown -R 65534:65534 /var/log/prometheus/
mkdir -p /var/log/grafana/ && chown -R 472:472 /var/log/grafana/
cp $HOME/monitoring/logrotate/prometheus /etc/logrotate.d/prometheus
cp $HOME/monitoring/logrotate/grafana /etc/logrotate.d/grafana

# setup prom & grafana with region
sed -i "s/PARAM_AZURE_LOCATION/$AZURE_LOCATION/g" $HOME/monitoring/docker-compose.yml
sed -i "s/PARAM_AZURE_LOCATION/$AZURE_LOCATION/g" $HOME/monitoring/prometheus/config/prometheus.yml
sed -i "s/PARAM_SUBSCRIPTION_ID/$SUBSCRIPTION_ID/g" $HOME/monitoring/prometheus/config/prometheus.yml

# setup config folders & fire up compose
mkdir -p /data
cp -R $HOME/monitoring/grafana/ $HOME/monitoring/prometheus/ $HOME/monitoring/docker-compose.yml /data/
chown -R $LOGIN_USER:$LOGIN_USER /data
chmod -R 777 /data/grafana /data/prometheus
cd /data && docker-compose up -d
