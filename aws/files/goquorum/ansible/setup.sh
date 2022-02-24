#!/bin/bash

echo $@ > /tmp/args.txt

GOQUORUM_VERSION=$1
GOQUORUM_NODE_TYPE=$2
GOQUORUM_PREFIX=$3
DNS_ZONE=$4
GOQUORUM_HOST_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
SCRIPTS_DIR="/home/ec2-user/goquorum"

sed -i "s/PARAM_GOQUORUM_VERSION/$GOQUORUM_VERSION/g" $SCRIPTS_DIR/goquorum.yml
sed -i "s/PARAM_GOQUORUM_HOST_IP/$GOQUORUM_HOST_IP/g" $SCRIPTS_DIR/goquorum.yml
sed -i "s/PARAM_GOQUORUM_PREFIX/$GOQUORUM_PREFIX/g" $SCRIPTS_DIR/static-nodes.json
sed -i "s/PARAM_DNS_ZONE/$DNS_ZONE/g" $SCRIPTS_DIR/static-nodes.json


mkdir -p /data/geth/
# copy keys across & set anything else up
mkdir -p /etc/goquorum
cp -r $SCRIPTS_DIR/keys/* /etc/goquorum/
cp $SCRIPTS_DIR/genesis.json /etc/goquorum/
cp $SCRIPTS_DIR/*.json /data/geth/
chown -R goquorum:goquorum /etc/goquorum/

cd $SCRIPTS_DIR
virtualenv $SCRIPTS_DIR/env
source $SCRIPTS_DIR/env/bin/activate
pip install wheel
pip install -r requirements.txt

# 2x becuase I keep seeing git timeouts when download the roles
ansible-galaxy install -r requirements.yml --force --ignore-errors
ansible-galaxy install -r requirements.yml --force --ignore-errors

# start in stopped state so paths and config are created
ansible-playbook -v goquorum.yml --extra-vars="goquorum_systemd_state=stopped"

# copy keys across & set anything else up
chown -R goquorum:goquorum /etc/goquorum/ /data

# fire up the service
systemctl start goquorum.service
