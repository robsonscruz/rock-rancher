# Env ROCK-DEVOPS

Cluster + Instance delivery according to model and value combinations, below are the tested and validated examples.

  - Terraform 1.0.3

## Any questions or suggestion?

Raise issues for asking help.

## Run terraform

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## 0. First of all - create SSL certificate
```bash
openssl req -new -x509 -keyout cert.pem -out cert.pem -days 365 -nodes

Country Name (2 letter code) [AU]:DE
State or Province Name (full name) [Some-State]:Germany
Locality Name (eg, city) []:nameOfYourCity
Organization Name (eg, company) [Internet Widgits Pty Ltd]:nameOfYourCompany
Organizational Unit Name (eg, section) []:nameOfYourDivision
Common Name (eg, YOUR name) []:*.yourdomain.com
Email Address []:your.email@domain.com
```

* Save two files on: "data/cert_priv.pem" and "data/cert_pub.pem"

* Generate Key Public
```bash
ssh-keygen -t rsa
```
* Save the files on: "data/cert.pub"

## 1. Create cluster + load balancer + route53 integrated on RancherServer
* Update the file "vars.tf" line 136: "default = '<domain.name>'" (inform the domain of your choice)
```bash
terraform apply -var "credentials_json=~/.ssh/key-gcp.json" -var "project=<id-project-gcp>"
```

## 2. Await publish of the k8s in new cluster
* Don't forget to add a GCP cluster configuration "~/.kube/config"

## 3. Add Traefik
* Update the file "user-data/traefik.yaml" line 22: "- host: traefik.<domain.name>" (same domain informed on step 3)
```bash
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
kubectl apply -f user-data/traefik.yaml

kubectl --namespace=kube-system get pods
```

## 4. Enable Longhorn
* Open cluster explorer in Rancher Server
* On right menu click in "rock-aws" if not selected
* On left menu click in "Cluster Explorer" and after in "Apps & Marketplace"
* Search app called "Longhorn" and select
* Click on button "install" (await a few moments to display a "Disconnected" message in red)
* Back on "Cluster Explorer" and select the namespace "Longhorn-system"

## 5. Access traefik and check ingress list + backend service
Access https://traefik.<domain.name>

## 6. Deploy APP - Rancher
* [App reference](https://github.com/robsonscruz/api-comments.git)
```bash
git clone https://github.com/robsonscruz/api-comments.git
```

* [Create cluster database](https://cloud.mongodb.com/)
* Replace MONGODB_URL connection in project "api-comments" -> path: deploy/values-http-prod.yaml line: 88
* Replace MONGODB_DB connection in project "api-comments" -> path: deploy/values-http-prod.yaml line: 89

### Test deploy APP
* helm install api-comments ./deploy/api-chart -f ./deploy/values-http-prod.yaml --dry-run --debug
### Deploy APP
helm install api-comments ./deploy/api-chart -f ./deploy/values-http-prod.yaml
## Config CI/CD - Github Action
* Fork [project](https://github.com/robsonscruz/api-comments.git) and configure "Github Actions"
* All variables are available in: .github/workflows/main.yaml

## 7. Enable Monitoring
* Open cluster explorer in Rancher Server
* On right menu click in "rock-aws" if not selected
* On left menu click in "Cluster Explorer" and after in "Apps & Marketplace"
* Search app called "Monitoring" and select
* Change to version 9.4.203
* Click on button "install" (await a few moments to display a "Disconnected" message in red)
* Back on "Cluster Explorer" and select the namespace "Monitoring" (Graphana, Prometheus, NodeExplorer)
## 10. Import dashboards
10000 e 8588