#!/bin/bash

yum update -y
yum install -y policycoreutils-python telnet bind-utils

cat <<EOF >>  /etc/hosts
192.168.33.10    master.k3s.dev
192.168.33.11    node1.k3s.dev
192.168.33.12    node2.k3s.dev
EOF