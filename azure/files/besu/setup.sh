#!/bin/bash

echo $@ > /tmp/args.txt

BESU_VERSION=$1
BESU_DOWNLOAD_URL=$2
BESU_BOOTNODE_IP=$3
# Get the host's private IP using the Azure metadata service
BESU_HOST_IP=`curl -H "Metadata:true" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text"`

sed -i "s/PARAM_BESU_VERSION/$BESU_VERSION/g" $HOME/besu/besu.yml
sed -i "s/PARAM_BESU_BOOTNODE_IP/$BESU_BOOTNODE_IP/g" $HOME/besu/besu.yml
sed -i "s/PARAM_BESU_HOST_IP/$BESU_HOST_IP/g" $HOME/besu/besu.yml
sed -i 's#PARAM_BESU_DOWNLOAD_URL#'"$BESU_DOWNLOAD_URL"'#g' $HOME/besu/besu.yml

cd $HOME/besu/
python3 -m venv env
source env/bin/activate
pip3 install wheel
pip3 install -r requirements.txt

# 2x becuase I keep seeing git timeouts when download the roles
ansible-galaxy install -r requirements.yml --force --ignore-errors
ansible-galaxy install -r requirements.yml --force --ignore-errors

# start in stopped state so paths and config are created
ansible-playbook -v besu.yml --extra-vars="besu_systemd_state=stopped"

# copy config across
cp ibft.json /etc/besu/genesis.json
chown besu:besu /etc/besu/genesis.json
cp node_db/* /opt/besu/data/
chown -R besu:besu /opt/besu/data/

# fire up the service
systemctl start besu.service
