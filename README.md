# K3S on Vagrant

## Table of Contents

- [K3S on Vagrant](#k3s-on-vagrant)
	- [Table of Contents](#table-of-contents)
	- [Introduction](#introduction)
	- [Nodes](#nodes)
	- [Installation](#installation)
		- [References](#references)

---

## Introduction

This is an overview of the process taken to create a sample k3s cluster. Some of the steps may not be fully detailed and some level of confort with Kubernetes and similar concepts is recommended.

## Nodes

| Node   | Hostname       | IP            | RAM (MB) |
| ------ | -------------- | ------------- | -------- |
| Master | master.k3s.dev | 192.168.33.10 | 2048     |
| Node1  | node1.k3s.dev  | 192.168.33.11 | 1024     |
| Node2  | node2.k3s.dev  | 192.168.33.12 | 1024     |

## Installation

1. On all nodes, update and install additional tooling and configure `/etc/hosts`

```bash
yum update -y
yum install -y policycoreutils-python telnet bind-utils

cat <<EOF >>  /etc/hosts
192.168.33.10    master.k3s.dev
192.168.33.11    node1.k3s.dev
192.168.33.12    node2.k3s.dev
EOF
```

2. Install the server component and obtain the token to use with the agents/clients

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable-agent" sh -

cat /var/lib/rancher/k3s/server/node-token
```

3. Copy the Token from the server & install the agent/client on the remaining nodes

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://master.k3s.dev:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

4. Validate the system is running properly and you can see all nodes and pods. Make sure to update your `.kube/config` or copy the config from the master node at `/etc/rancher/k3s/k3s.yaml`

```bash
kubectl get nodes -o wide
kubectl get pods --all-namespaces -o wide
```

5. To install metrics, clone the k3s git repo and `apply` all the files in the `recipes/metrics-server`

```bash
git clone https://github.com/rancher/k3s.git

kubectl apply -f recipes/metrics-server
```

6. Creating a storage class for the cluster

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl get storageclass
```

7. Install Helm and/or Link Helm with Tiller

```bash
#Install Helm
##download helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh

##Make instalation script executable
chmod u+x install-helm.sh

##Install helm
./install-helm.sh

#---
#Linking
##Create tiller service account
kubectl -n kube-system create serviceaccount tiller

##Create cluster role binding for tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

##Initialize tiller
helm init --service-account tiller
```

8. Install Kube-Ops-View & then add it to ingress

```bash
helm install --name=kube-ops stable/kube-ops-view
kubectl apply -f kube-ops-ingress.yaml
```

9. Install OpenFaas

```bash
#Create namespaces
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

#Add OpenFaaS repo to helm
helm repo add openfaas https://openfaas.github.io/faas-netes/

# generate a random password
PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password="$PASSWORD"

# (1) Update Helm repo & Install
helm repo update \
 && helm upgrade openfaas --install openfaas/openfaas \
    --namespace openfaas  \
    --set basic_auth=true \
    --set functionNamespace=openfaas-fn \
    --set faasnetes.httpProbe=true \
    --set ingress.enabled=true

# (2) OR if you already have everything setup, just install
helm install openfaas/openfaas \
    --namespace openfaas  \
    --set basic_auth=true \
    --set functionNamespace=openfaas-fn \
    --set faasnetes.httpProbe=true \
    --set ingress.enabled=true
```

---

### References

- K3S:
  - <https://github.com/rancher/k3s>
- OpenFaaS:
  - <https://github.com/openfaas/faas-netes/>
  - <https://hub.helm.sh/charts/openfaas/openfaas>
- Kube-Ops-View:
  - <https://github.com/hjacobs/kube-ops-view>
  - <https://hub.kubeapps.com/charts/stable/kube-ops-view>
  - <https://github.com/hjacobs/kube-ops-view/blob/master/deploy/ingress.yaml>