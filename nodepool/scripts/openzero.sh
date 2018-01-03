#!/bin/bash -xe

# Copyright (C) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,

#
# See the License for the specific language governing permissions and
# limitations under the License.
if [ -f "/etc/nodepool/provider" ]; then
    source /etc/nodepool/provider
fi

# Generate the AFS Slug from the host system.
source /usr/local/jenkins/slave_scripts/afs-slug.sh

# set DNS address for openstack env
echo "nameserver 172.10.0.1" |sudo tee /etc/resolv.conf

echo "127.0.0.1 localhost"|sudo tee /etc/hosts
echo "127.0.1.1 ubuntu"|sudo tee -a /etc/hosts

# DhClient will delete all DNS when release expire.
# So if only modify the /etc/resolv.conf, it will out of operation after a
# release cycle.
# To resolve the issue, need to modify /sbin/dhclient-script which dhclient
# will call when dhclient sets each interface's initial configuration.
# It will override the default behaviour of the client in creating a
# /etc/resolv.conf file
sudo sed -i -e '/mv -f $new_resolv_conf $resolv_conf/a\
        echo "nameserver 172.10.0.1" > $resolv_conf' /sbin/dhclient-script

cat << EOF > ~/.ssh/config
#Host gerrit.oz
#        KexAlgorithms +diffie-hellman-group1-sha1
Host *
        StrictHostKeyChecking no
EOF

cat << EOF > ~/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAx2hD99aqVztQ2VaFQ74q0vIGDZIg8VsiS0seZzQefFirNdf2
i1+B8z9GPlnCMx4aJZ8pxnAW6Rv/XslKW3dsLAUvLSbSXAnIxwayf273zI5VMke7
oaVOz5NRYKsgr2O7mhiU4YTFYo0OfQWPBOWECKGbvg53o1agDMhKGxNLXEsCCrq0
WxGo8r68df3/6Pn3iMuQGz4yFaigqCI34K5BW4nGKNCwfh3f8xCN0rpMlOCqhxx5
cmevohpJRfHIWST5yTPUIUKRlU8Pdwtd41tg7Fs8+QrTlIEWwdRkMcxAv8NxieSr
7QinhAIgL6Fqh+UrKVIW0ac3wmL74Uc200WwywIDAQABAoIBAHCmD1eQVpSG9sqA
3TIC2TBn91FtTtzqTfpZCmjlAZ/fe4EkaqwbnU7sXONWU6YLCFxeiPwIUHkKDv7e
GfqIAXzwxNDuEIJcKKd+uhHRf314ntqTuYS83UPYhm1k30cVwWJxJpIsLlHZO+kW
3c+3VRqHKXN5us50XmA6OdsH0FfnLItzmzgllsYVP6bwlCrM20c8QNJvaSZrBZoF
+x0aZE7iXrFBZPv6TxD1teI00Lr9k6+XsDC84m4DKFYKlK53RC9nQSp1ldvmMglK
Gzn/YIOpD8nL5X2fJZ+lP7eWPGhpv+B8WRqJ0NLld8teprorPBGl89vUvjKg2bGr
1tIE64ECgYEA4//WqDlSoUAzMO85W7Fb+ZYCFQrO0kwMjtx5XC44hi2a2k+MOMQO
Mw5l3gS4GGkmMULEUXuXzNy6YMci4v6KlozHrNzz8A43kmYNJEFA14w8cd/SO+JH
MQpnSC5nGXKUfzKHE1/cxd5KchampQf70ZI3e7wRW1PhvkhWVtkenUECgYEA3+WC
Yzdc1gn1ptZ/wBgpkenpclVL0K1D8w9LXVpCqfI/nipgFwX0PqiSxShbbG+5g8oz
sJ1kQ/h0ryhuawp2hh9gxl/NKM8UWYkj+bMtuJ2rlfQnaicl4n0jB9Sjh8URZ8cO
UNHpA7l9xbLDuv2c2E7zIHDxsaX5PdtIc7yWLwsCgYBuoHlQIJg2Q4dTLBABrJn7
DU0vVpIpudqyCsob7xVgDYrAeK6J8J8PKOJGirWkqohsiH/nJXfvX/5S7OzBhU5L
ZD2SY5c9GDjgoQGpYLwMmi/N9RL2GYH/ipO4k0NVNqJU4Xhm7zGZFJW8q77p/miy
NCcVs5gcXyP+huzVsP3IwQKBgQC4a7WQv+NqMl3zhK9JrR1goQm3MWb3hiB4Ltrn
FBfhIDcissjfbfoXOodaermDgiuO0JjvG1WhXx/Nv0HkTYP/Sg1OmU7GFHwwm/PU
E7DPZqAVLjzhBUoBWw3lv1LL3JlPn/i8vYpvlPRySaNLfOcajT1aNW3/5DR+rQbq
viX+rQKBgEbhVrM4LVmnglxaJ80fAq59qjgZwJcQG9xTrFkixjbYAu+zH0Az4RdW
0Hxb77XbuKkKameAmdsV7gee2DC1YwCrIXCxMOa0nQfuGw4BPmEgSrU4YnOI0y1m
zXTg0W8lo/QrnUge4mfRDVlVb9mwlawqJQlYPnydYMX9yhnGvdmj
-----END RSA PRIVATE KEY-----
EOF

chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config

if [ $USER -ne "root" ]; then
    sudo cp ~/.ssh/config  ~root/.ssh/
    sudo cp ~/.ssh/id_rsa ~root/.ssh/
fi


# Double check that when the node is made ready it is able
# to resolve names against DNS.
host git.openstack.org

LSBDISTID=$(lsb_release -is)
LSBDISTCODENAME=$(lsb_release -cs)
# NOTE(pabelanger): We don't actually have mirrors for ubuntu-precise, so skip
# them.
