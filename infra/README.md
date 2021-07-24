# Env ROCK-DEVOPS

Cluster + Instance delivery according to model and value combinations, below are the tested and validated examples.

  - Terraform 1.0

## Any questions or suggestion?

Raise issues for asking help.

## Run terraform

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## 1. Create Rancher Server
```bash
terraform apply -target=aws_instance.rancher
```

## 2. Access Rancher and configure (Retrieve the IP shown in the Terraform output)
* Add new cluster
* Create a new Kubernetes cluster: Existing nodes
* Set name: "rock-aws"
* In "advanced options" checked "Disabled" for "Nginx Ingress" and "Nginx Default Backend"
* Click in NEXT
* In "Node Options": checked "etcd", "Control Plane" and "Worker"
* Copy command shown below.
* Save content copied and replace content on  line 5 of the file "./user-data/k8s.sh" (replace content of the line)

## 3. Create cluster + load balancer + route53 integrated on RancherServer
```bash
terraform apply -target=aws_autoscaling_attachment.asg_attachment -target=aws_autoscaling_policy.autopolicy -target=aws_route53_record.main
```

## 4. Add Traefik
```bash
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
kubectl apply -f user-data/traefik.yaml

kubectl --namespace=kube-system get pods
```

## 5. Config Longhorn

## @todo - enable ports in security groups ##