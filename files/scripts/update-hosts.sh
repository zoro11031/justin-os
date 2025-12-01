#!/usr/bin/env bash

set -ouex pipefail

# Append hosts
echo "192.168.7.179 unraid.lan" >> /etc/hosts
echo "192.168.3.51 minipc.lan" >> /etc/hosts
