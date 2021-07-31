#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# Config rancher-server
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.9 --server https://3.84.62.35 --token bwfc7bbzbgf75fl52j8vnnwgpb4x8xdtkdszwlwzvntd7rpwd8lvff --ca-checksum e570b6330d19f7f10aa5725d4df454673dfb64f78fa4de5870a55a55a019e18b --etcd --controlplane --worker