#!/bin/bash

#KUBEADM_VERBOSITY=
#KUBEADM_VERBOSITY="-v 5"
KUBEADM_VERBOSITY="-v 4"

# adapted from: https://www.avthart.com/posts/create-your-own-minikube-using-vagrant-and-kubeadm/ / https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3

# Kubelet requires swap off (after reboot):
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "Install kubeadm"
sudo apt-get update
sudo apt-get install -y kubeadm

# Force use of systemd driver for cgroups since kubelet will use cri-o
#echo "Configure cgroup driver for kubelet"
#cat <<EOF |  sudo tee /etc/default/kubelet
#KUBELET_EXTRA_ARGS=--cgroup-driver=systemd 
#EOF
#sudo systemctl daemon-reload
#sudo systemctl restart kubelet
#exit 0
#
# Add docker.io registry of images
#echo "Configure container registries to include docker.io"
#sudo sed -i 's/#registries = \[/registries = \["docker.io"\]/g' /etc/crio/crio.conf
#cat <<EOF |  sudo tee /etc/containers/registries.conf
# This is a system-wide configuration file used to
# keep track of registries for various container backends.
# It adheres to TOML format and does not support recursive
# lists of registries.

# The default location for this configuration file is /etc/containers/registries.conf.

# The only valid categories are: 'registries.search', 'registries.insecure', 
# and 'registries.block'.

#[registries.search]
#registries = ['docker.io']

# If you need to access insecure registries, add the registry's fully-qualified name.
# An insecure registry is one that does not have a valid SSL certificate or only does HTTP.
#[registries.insecure]
#registries = []


# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
#
# Docker only
#[registries.block]
#registries = []
#EOF
#sudo systemctl daemon-reload
#sudo systemctl restart crio
#exit 0
#echo "Pulling container images for Kubernetes"
#sudo kubeadm config images pull --cri-socket=/var/run/crio/crio.sock
#sudo kubeadm config images pull

echo "Create cluster"
# Install using kubeadm
# First interface with default route set to it
INTERFACE=$(sudo /sbin/route | grep '^default' | grep -o '[^ ]*$' | head -n 1)
IPADDR=`sudo ifconfig $INTERFACE | grep -i mask | awk '{print $2}'| cut -f2 -d:`
NODENAME=$(hostname -s)

#sudo kubeadm init --apiserver-cert-extra-sans=$IPADDR  --node-name $NODENAME --cri-socket=/var/run/crio/crio.sock --pod-network-cidr=192.168.0.0/16

# The --cgroup-driver=systemd kubelet option being deprecated, we use the KubeletConfiguration config item to set it
# but this forces us to get rid of other kubeadm options, which end up in the same config file
cat <<EOF |  sudo tee /root/kubeadmin-config.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
apiServer:
  certSANs:
  - "IPADDR"
networking:
  podSubnet: "192.168.0.0/16"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"

EOF
sudo sed -i "s/IPADDR/$IPADDR/g" /root/kubeadmin-config.yaml

#sudo kubeadm init -v 5 --config /root/kubeadmin-config.yaml --cri-socket /run/containerd/containerd.sock --node-name $NODENAME
sudo kubeadm init $KUBEADM_VERBOSITY --config /root/kubeadmin-config.yaml --node-name $NODENAME

# Copy admin credentials to vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $USER:$USER $HOME/.kube

sleep 60

# remove master role taint
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l k8s-app=kube-proxy
sleep 60

kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l component=etcd

