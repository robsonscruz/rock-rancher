#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# Config rancher-server
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.9 --server https://3.92.206.21 --token z2brc79w4qczwblt7dpx8cd526nxj9jptmsbdb86ntqppdpx7wb8m6 --ca-checksum bbd5627acfb3269436652cf125d23b92a06c3f593da3c5bac67a03a82fe8553b --etcd --controlplane --worker