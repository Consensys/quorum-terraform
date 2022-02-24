#!/bin/bash
for key in "$@"
do
  echo "appending key to authorized_keys $key"
  echo "$key" >> $HOME/.ssh/authorized_keys
done
