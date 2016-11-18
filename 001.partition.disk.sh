#!/bin/bash

# Instructions from: 
# https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/


# Create a physical volume (use whole disk mounted as /dev/sdb)
sudo pvcreate /dev/sdb

#  Create a  volume group called 'lvmpart' (for LVM partition)
sudo vgcreate lvmpart /dev/sdb


# Create a thin pool named thinpool to be used by Docker
sudo lvcreate --wipesignatures y -n thinpool --size 20G lvmpart
sudo lvcreate --wipesignatures y -n thinpoolmeta --size 500M lvmpart

# Convert the Docker pool to a thin pool.
sudo lvconvert -y --zero n -c 512K --thinpool lvmpart/thinpool --poolmetadata 
lvmpart/thinpoolmeta

# Configure autoextension of thin pools via an lvm profile.
sudo mkdir /etc/lvm/profile

sudo bash -c "cat <<EOT >> /etc/lvm/profile/lvmpart-thinpool.profile 
activation {
    thin_pool_autoextend_threshold=80
    thin_pool_autoextend_percent=20
}
EOT"

# Apply profile
sudo lvchange --metadataprofile lvmpart-thinpool lvmpart/thinpool


###########################################
# Now create a volume to be used as /home
sudo lvcreate -n homevol lvmpart --size 15G

# and format it as ext4
sudo mkfs.ext4 /dev/lvmpart/homevol

# change volume label to lvm-home for easy mounting
sudo e2label /dev/mapper/lvmpart-homevol "lvm-home"


###########################################
# Now create a volume to be used as /data
sudo lvcreate -n homevol lvmpart --size 20G

# and format it as ext4
sudo mkfs.ext4 /dev/lvmpart/datavol

# change volume label to lvm-data for easy mounting
sudo e2label /dev/mapper/lvmpart-datavol "lvm-data"

