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
* Update the file "vars.tf" line 85: "default = '<domain.name>'" (inform the domain of your choice)
```bash
terraform apply -target=aws_autoscaling_attachment.asg_attachment \
  -target=aws_cloudwatch_metric_alarm.cpualarm \
  -target=aws_cloudwatch_metric_alarm.cpualarm-down \
  -target=aws_cloudwatch_metric_alarm.memory-high \
  -target=aws_cloudwatch_metric_alarm.memory-low \
  -target=aws_route53_record.main
```

## 4. Add Traefik
* Update the file "user-data/traefik.yaml" line 22: "- host: traefik.<domain.name>" (same domain informed on step 3)
```bash
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
kubectl apply -f user-data/traefik.yaml

kubectl --namespace=kube-system get pods
```

## 5. Enable Longhorn
* Open cluster explorer in Rancher Server
* On right menu click in "rock-aws" if not selected
* On left menu click in "Cluster Explorer" and after in "Apps & Marketplace"
* Search app called "Longhorn" and select
* Click on button "install" (await a few moments to display a "Disconnected" message in red)
* Back on "Cluster Explorer" and select the namespace "Longhorn-system"

## 6. Access traefik and check ingress list + backend service
Access https://traefik.<domain.name>

## 7. Deploy APP - Rancher
### Test deploy APP
* helm install api-comments ./deploy/api-chart -f ./deploy/values-http-prod.yaml --dry-run --debug
### Deploy APP
helm install api-comments ./deploy/api-chart -f ./deploy/values-http-prod.yaml
## Config CI/CD - Github Action
* OK
## 9. Enable Monitoring
* OK
## Enable ports in security groups ##
* OK

## Erro 502 Bad Request
* https://github.com/rancher/rancher/issues/25035