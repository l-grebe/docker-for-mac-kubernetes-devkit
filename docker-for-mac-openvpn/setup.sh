#!/bin/bash

set -ex

CONFIGS_DIR="/etc/openvpn"
SERVER_CONFIG="${CONFIGS_DIR}/openvpn.conf"

LOCAL_DIR="/local"
CLIENT_CONFIG="${LOCAL_DIR}/docker-for-mac.ovpn"

if [ ! -f ${CLIENT_CONFIG} ]; then
    # Generating files
    ovpn_genconfig -u tcp://localhost
    echo localhost | ovpn_initpki nopass

    # Build client config
    easyrsa build-client-full host nopass
    ovpn_getclient host > ${CLIENT_CONFIG}

    # Update configs
    sed -i "s|^push|#push|" ${SERVER_CONFIG}
    sed -i "s|^route|#route|" ${SERVER_CONFIG}
    sed -i "s|^port 1194|port 1194|" ${SERVER_CONFIG}
    sed -i "s|^port 1194|port 31194|" ${CLIENT_CONFIG}
    sed -i "s|^redirect-gateway|#redirect-gateway|" ${CLIENT_CONFIG}
fi

# update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
# systemctl stop firewall

/sbin/iptables -I FORWARD 1 -i tun+ -j ACCEPT

exec ovpn_run
