#!/bin/bash
docker buildx build --platform linux/amd64 --file openvpn.dockerfile --tag openvpn:local .
docker tag openvpn:local vmele.com/klx/openvpn:local
docker push vmele.com/klx/openvpn:local

