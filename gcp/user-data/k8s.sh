#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# Config rancher-server
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.9 --server https://3.86.232.143 --token 6l5ktkwxmvh4bpbbghf7wmb2w6662t86vhl52s9c6h9ck9nr2m2mdj --ca-checksum 70698c740318aeead33d7dbcf8d8694c3e47ce0bddfb4c083976c919f6fd95cd --etcd --controlplane --worker