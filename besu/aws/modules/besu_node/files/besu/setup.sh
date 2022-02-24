#!/bin/bash

echo $@ > /tmp/args.txt

BESU_VERSION=$1
BESU_BOOTNODE_IP=$2
RUN_USER=$3
# Get the host's private IP using the AWS metadata service
BESU_HOST_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

sed -i "s/PARAM_BESU_VERSION/$BESU_VERSION/g" /home/$RUN_USER/besu/besu.yml
sed -i "s/PARAM_BESU_BOOTNODE_IP/$BESU_BOOTNODE_IP/g" /home/$RUN_USER/besu/besu.yml
sed -i "s/PARAM_BESU_HOST_IP/$BESU_HOST_IP/g" /home/$RUN_USER/besu/besu.yml
# sed -i 's#PARAM_BESU_DOWNLOAD_URL#'"$BESU_DOWNLOAD_URL"'#g' /home/$RUN_USER/besu/besu.yml

cd /home/$RUN_USER/besu/
python3 -m venv env
source env/bin/activate
pip3 install wheel
pip3 install -r requirements.txt

# 2x becuase of some random git timeouts
ansible-galaxy install -r requirements.yml --force --ignore-errors
ansible-galaxy install -r requirements.yml --force --ignore-errors

# start in stopped state so paths and config are created
ansible-playbook -v besu.yml --extra-vars="besu_systemd_state=stopped"

# copy config across
cp ibft.json /etc/besu/genesis.json
chown besu:besu /etc/besu/genesis.json
cp key /opt/besu/data/
chown -R besu:besu /opt/besu/data/

# fire up the service
systemctl start besu.service
