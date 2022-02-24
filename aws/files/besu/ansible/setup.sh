#!/bin/bash

echo $@ > /tmp/args.txt

BESU_VERSION=$1
BESU_BOOTNODE_IP=$2
BESU_NODE_TYPE=$3
BESU_PREFIX=$4
DNS_ZONE=$5
BESU_HOST_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
SCRIPTS_DIR="/home/ec2-user/besu"

sed -i "s/PARAM_BESU_VERSION/$BESU_VERSION/g" $SCRIPTS_DIR/besu.yml
sed -i "s/PARAM_BESU_HOST_IP/$BESU_HOST_IP/g" $SCRIPTS_DIR/besu.yml
sed -i "s/PARAM_BESU_PREFIX/$BESU_PREFIX/g" $SCRIPTS_DIR/static-nodes.json
sed -i "s/PARAM_DNS_ZONE/$DNS_ZONE/g" $SCRIPTS_DIR/static-nodes.json

if [[ "$BESU_BOOTNODE_IP" == "self" ]]; then
    sed -i "s/PARAM_BOOTNODE_IP/$BESU_HOST_IP/g" $SCRIPTS_DIR/besu.yml
else
    sed -i "s/PARAM_BOOTNODE_IP/$BESU_BOOTNODE_IP/g" $SCRIPTS_DIR/besu.yml
fi


mkdir -p /opt/log4j
mv $SCRIPTS_DIR/besu-log-config.xml /opt/log4j/
chown -R ec2-user:ec2-user /opt/log4j/
mkdir /data

mkdir -p /etc/besu
cp -r /home/ec2-user/besu/keys/* /etc/besu/
cp $SCRIPTS_DIR/genesis.json /etc/besu/
cp $SCRIPTS_DIR/static-nodes.json /data/
chown -R besu:besu /etc/besu/

cd $SCRIPTS_DIR
virtualenv $SCRIPTS_DIR/env
source $SCRIPTS_DIR/env/bin/activate
pip install wheel
pip install -r requirements.txt

# 2x becuase git timeouts when download the roles
ansible-galaxy install -r requirements.yml --force --ignore-errors
ansible-galaxy install -r requirements.yml --force --ignore-errors

# start in stopped state so paths and config are created
ansible-playbook -v besu.yml --extra-vars="besu_systemd_state=stopped"

# copy keys across & set anything else up
chown -R besu:besu /etc/besu/ /data

# fire up the service
systemctl start besu.service
