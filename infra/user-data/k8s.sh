#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# Config rancher-server
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.9 --server https://52.91.80.242 --token zz2n5s4tpnzs24bxqhrs4q7bnlf2pzfz54tk8dznlkj6mzxlmsqmjc --ca-checksum e7a168a954b0767f504ef204c6b986e407646840591e7f03ed5853b327cb878b --etcd --controlplane --worker