#!/bin/bash
# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# To run on Ubuntu 14.04, this depends on:
# diskimage-builder
# qemu-utils
# debootstrap

set -e

sudo apt-get install -y --force-yes qemu-utils
sudo apt-get install -y --force-yes debootstrap
sudo pip install -U diskimage-builder

ELEMENTS_PATH=${ELEMENTS_PATH:-$WORKSPACE/nodepool/elements}
DISTRO=${DISTRO:-ubuntu-minimal}
IMAGE_NAME=${IMAGE_NAME:-devstack-gate}
NODEPOOL_SCRIPTDIR=${NODEPOOL_SCRIPTDIR:-$WORKSPACE/nodepool/scripts}
CONFIG_SOURCE=${CONFIG_SOURCE:-https://git.openstack.org/openstack-infra/system-config}
CONFIG_REF=${CONFIG_REF:-master}
EXTRA_ELEMENTS=${EXTRA_ELEMENTS:-}


ZUUL_USER_SSH_PUBLIC_KEY=${ZUUL_USER_SSH_PUBLIC_KEY:-/tmp/id_rsa.pub}
if [ ! -f ${ZUUL_USER_SSH_PUBLIC_KEY} ]; then
    cat << EOF > /tmp/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHaEP31qpXO1DZVoVDvirS8gYNkiDxWyJLSx5nNB58WKs11/aLX4HzP0Y+WcIzHholnynGcBbpG/9eyUpbd2wsBS8tJtJcCcjHBrJ/bvfMjlUyR7uhpU7Pk1FgqyCvY7uaGJThhMVijQ59BY8E5YQIoZu+DnejVqAMyEobE0tcSwIKurRbEajyvrx1/f/o+feIy5AbPjIVqKCoIjfgrkFbicYo0LB+Hd/zEI3SukyU4KqHHHlyZ6+iGklF8chZJPnJM9QhQpGVTw93C13jW2DsWzz5CtOUgRbB1GQxzEC/w3GJ5KvtCKeEAiAvoWqH5SspUhbRpzfCYvvhRzbTRbDL
EOF
fi

## If your firewall won't allow outbound DNS connections, you'll want
## to set these to local resolvers
# export NODEPOOL_STATIC_NAMESERVER_V4=192.168.0.1
# export NODEPOOL_STATIC_NAMESERVER_V6=2000::...

## This will get dib to drop you into a shell on error, useful for debugging
# export break="after-error"

## If you need to debug the boot, setting this longer might help you
## break into the grub console.  Or set it to 0 for fast boot.
# export DIB_GRUB_TIMEOUT=10

## The openstack-repos element caches every git repo, wihch can take
## quite some time.  We can override this, but some minimal repos are
## required for a successful build.  For speeding up builds when
## you're testing the following should work, but be very careful
## stripping things out when generating real images.

## add to /tmp/custom_projects.yaml:
##
## - project: openstack-infra/project-config
## - project: openstack-infra/system-config
## - project: openstack-dev/devstack
## - project: openstack/tempest

# export DIB_CUSTOM_PROJECTS_LIST_URL='file:///tmp/custom_projects.yaml'

## If you are building test images, or dealing with networking issues,
## you will want to have a local login with password available (as
## opposed to key-based ssh only).  You can use the "devuser" element
## from dib to set this up.  Don't forget to enable sudo and set the
## password.

## defaults
## export DIB_DEV_USER_USERNAME=devuser
## export DIB_DEV_USER_AUTHORIZED_KEYS=$HOME/.ssh/id_rsa.pub

# EXTRA_ELEMENTS+=devuser
# export DIB_DEV_USER_PWDLESS_SUDO=1
# export DIB_DEV_USER_PASSWORD=devuser

# The list of elements here should match nodepool/nodepool.yaml
sudo ELEMENTS_PATH=$ELEMENTS_PATH DISTRO=$DISTRO IMAGE_NAME=$IMAGE_NAME \
    NODEPOOL_SCRIPTDIR=$NODEPOOL_SCRIPTDIR CONFIG_SOURCE=$CONFIG_SOURCE \
    CONFIG_REF=$CONFIG_REF EXTRA_ELEMENTS=$EXTRA_ELEMENTS \
    ZUUL_USER_SSH_PUBLIC_KEY=$ZUUL_USER_SSH_PUBLIC_KEY \
    disk-image-create -x --no-tmpfs -o $IMAGE_NAME \
    $DISTRO \
    vm \
    cache-devstack \
    infra-package-needs \
    initialize-urandom \
    jenkins-slave \
    simple-init \
    openstack-repos \
    nodepool-base \
    prepare-node \
    zuul-worker \
    growroot \
    stackviz \
    openzero

echo "Created new image: $IMAGE_NAME"
echo "You can now upload it with:"
echo "  openstack image create "${DISTRO}" --file $IMAGE_NAME --disk-format=qcow2 --container-format bare"
