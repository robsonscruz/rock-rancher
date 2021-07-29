#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# Config rancher-server
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.9 --server https://3.86.232.143 --token vzvfwlzbhlzbz4nt27vwxjqgd6bn9gkrblr9l2kjb94sqdq8hjvmcl --ca-checksum 70698c740318aeead33d7dbcf8d8694c3e47ce0bddfb4c083976c919f6fd95cd --etcd --controlplane --worker