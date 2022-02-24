#!/bin/bash
set -e -x

function _create_xfs_filesystem (){
  # check that it doesnt have a fs before wiping i.e if its healing and recovers with an existing volume leave it as is
  fs_check=$(file -s $1)
  if [[ $fs_check == *"filesystem"* ]]; then
    echo "Existing filesystem... "
  else
    echo "No filesystem found, creating one..."
    mkfs.xfs $1
  fi
}

# $1 = /dev/nvme1n1 (device)
# $2 = /data (path)
function _mount_filesystem_at (){
  mkdir $2 && chown -R ec2-user:ec2-user $2
  UUID=$(blkid $1 | grep -oP '(UUID=).*(?=TYPE)' | sed -e 's/"//g')
  echo "$UUID      $2   xfs    defaults,nofail  0  2" >> /etc/fstab
  mount -a
  chown -R ${login_user}:${login_user} $2 && chmod -R 777 $2
}

# For the general case t3 (etc) box, this is used as the data directory and we mount to /data
ebs_device_id=$(lsblk | grep ${besu_data_volume_size/1000}T | grep -o "^\w*\b")
ebs_device=/dev/$ebs_device_id
_create_xfs_filesystem "$ebs_device"
_mount_filesystem_at "$ebs_device" /data