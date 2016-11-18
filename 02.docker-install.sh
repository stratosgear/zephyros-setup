#!/bin/bash

# Instalation script from:
# https://docs.docker.com/engine/installation/linux/ubuntulinux/

# Update your apt sources
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
apt-cache policy docker-engine

# Prerequisites by Ubuntu Version
sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual

# Install Docker
sudo apt-get -y install docker-engine
#sudo service docker start

# make docker start on boot
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Switch to LVM usage for devicemapper
# Instructions from: https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/
# NOTE: Make sure you have correctly setup the LVM partitions from 001.partition-disk.sh

# NOTE: Make sure you use the correct /dev/mapper location below
sudo -s -- <<EOT
echo "DOCKER_OPTS=\"--storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/lvmpart-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true\"" >> /etc/default/docker
EOT

# NOTE: Make sure you use the correct /dev/mapper location below
sudo touch /etc/docker/daemon.json
sudo bash -c "cat <<EOT >> /etc/docker/daemon.json
{
  "storage-driver": "devicemapper",
   "storage-opts": [
     "dm.thinpooldev=/dev/mapper/lvmpart-thinpool",
     "dm.use_deferred_removal=true",
     "dm.use_deferred_deletion=true"
   ]
}
EOT"

sudo service docker start

# Verify everything is working ok
docker run hello-world
docker info
