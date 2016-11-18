#!/bin/bash

# Updateable params:
$lvmdisk=/dev/sdc

# Instalation script from:
# https://docs.docker.com/engine/installation/linux/ubuntulinux/



# Update your apt sources
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
apt-cache policy docker-engine

# Prerequisites by Ubuntu Version
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual

# Install Docker
sudo apt-get install docker-engine
sudo service docker start

# make docker start on boot
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER


# Instructions from: https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/
# Switch to LVM usage for devicemapper
sudo service docker stop

sudo pvcreate $lvmdisk
sudo vgcreate docker $lvmdisk
sudo lvcreate --wipesignatures y -n thinpool docker -l 95%VG
sudo lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
sudo lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

sudo mkdir /etc/lvm/profile
sudo touch /etc/lvm/profile/docker-thinpool.profile
sudo bash -c "cat <<EOT >> /etc/lvm/profile/docker-thinpool.profile                   │
activation {                                                                                              │
    thin_pool_autoextend_threshold=80                                                                     │
    thin_pool_autoextend_percent=20                                                                       │
}                                                                                                         │
EOT"

sudo lvchange --metadataprofile docker-thinpool docker/thinpool
sudo -s -- <<EOT
echo "DOCKER_OPTS=\"--storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true\"" >> /etc/
EOT

sudo touch /etc/docker/daemon.json
sudo bash -c "cat <<EOT >> /etc/docker/daemon.json
{
  "storage-driver": "devicemapper",
   "storage-opts": [
     "dm.thinpooldev=/dev/mapper/docker-thinpool",
     "dm.use_deferred_removal=true",
     "dm.use_deferred_deletion=true"
   ]
}

sudo service docker start

# Verify everything is working ok
sudo docker run hello-world
docker info


