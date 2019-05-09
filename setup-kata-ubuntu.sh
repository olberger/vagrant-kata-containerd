#!/bin/bash

# source: https://github.com/kata-containers/packaging/tree/master/kata-deploy#kubernetes-quick-start
echo "Installing Kata-Containers"
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-deploy.yaml


print_progress() {
    percentage=$1
    chars=$(echo "40 * $percentage"/1| bc)
    v=$(printf "%-${chars}s" "#")
    s=$(printf "%-$((40 - chars))s")
    echo "${v// /#}""${s// /-}"
}

running_system_pods=0
total_system_pods=$(kubectl get pods --all-namespaces | tail -n +2 | wc -l)
while [ $running_system_pods -lt $total_system_pods ]
do
    running_system_pods=$(kubectl get pods --all-namespaces | grep Running | wc -l)
    percentage="$( echo "$running_system_pods/$total_system_pods" | bc -l )"
    echo -ne $(print_progress $percentage) "${YELLOW}Installing additional infrastructure components...${NC}\r"
    sleep 1
done

# Clear line and print finished progress
echo -ne "$pc%\033[0K\r"
echo -ne $(print_progress 1) "${GREEN}Done.${NC}\n"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/node-api/master/manifests/runtimeclass_crd.yaml
#kubectl apply -f https://raw.githubusercontent.com/clearlinux/cloud-native-setup/master/clr-k8s-examples/8-kata/kata-qemu-runtimeClass.yaml
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/k8s-1.14/kata-qemu-runtimeClass.yaml

kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l name=kata-deploy
