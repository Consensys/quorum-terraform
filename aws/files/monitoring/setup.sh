#!/bin/bash

AWS_REGION=$1
RESOURCE_PREFIX=$2

# logrotate
# 65534 & 472 are the respective container user:group pairs
mkdir -p /var/log/prometheus/ && chown -R 65534:65534 /var/log/prometheus/
mkdir -p /var/log/grafana/ && chown -R 472:472 /var/log/grafana/
cp /home/$USER/monitoring/logrotate/prometheus /etc/logrotate.d/prometheus
cp /home/$USER/monitoring/logrotate/grafana /etc/logrotate.d/grafana

# setup prom & grafana with region
sed -i "s/PARAM_AWS_REGION/$AWS_REGION/g" /home/$USER/monitoring/docker-compose.yml
sed -i "s/PARAM_AWS_REGION/$AWS_REGION/g" /home/$USER/monitoring/prometheus/config/prometheus.yml
sed -i "s/PARAM_RESOURCE_PREFIX/$RESOURCE_PREFIX/g" /home/$USER/monitoring/prometheus/config/prometheus.yml

# setup config folders & fire up compose
mkdir -p /data
cp -R /home/$USER/monitoring/grafana/ /home/$USER/monitoring/prometheus/ /home/$USER/monitoring/docker-compose.yml /data/
cp -R /home/$USER/monitoring/alertmanager/ /data/
chown -R $USER:$USER /data
chmod -R 777 /data/grafana /data/prometheus
cd /data && /usr/local/bin/docker-compose up -d