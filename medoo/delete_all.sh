sudo /usr/local/bin/k3s-uninstall.sh
sudo kubeadm reset
sudo rm -rf ~/.kube /etc/kubernetes /var/lib/etcd
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo apt-get autoremove -y
sudo apt-get clean
sudo systemctl stop k3s
sudo systemctl disable k3s
sudo systemctl stop kubelet
sudo systemctl disable kubelet
sudo /usr/local/bin/k3s-uninstall.sh
sudo kubeadm reset
sudo rm -rf ~/.kube
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo apt-get purge -y kubectl
sudo rm -rf /etc/kubernetes
sudo rm -rf /etc/docker
sudo rm -rf /var/lib/kubelet
sudo rm /usr/local/bin/helm
sudo systemctl daemon-reload
sudo systemctl reset-failed
sudo apt-get autoremove -y
sudo apt-get clean


kubectl delete all --all -n default
kubectl get ns --no-headers | awk '{print $1}' | xargs kubectl delete ns
kubectl get ns --no-headers | awk '{print $1}' | grep -vE '^(default|kube-system|kube-public|kube-node-lease)$' | xargs kubectl delete ns
kubectl delete all --all --all-namespaces
kubectl delete all --all
kubectl delete namespace app cert-manager db erpnext ingress-nginx kube-flannel local-path-storage metallb-system nfs zatca-men
kubectl get namespaces --no-headers | awk '{print $1}' | grep -vE 'default|kube-system|kube-public|kube-node-lease' | xargs kubectl delete namespace
helm list -A -q | xargs -r helm uninstall -n
helm list -A --format '{{.Name}} {{.Namespace}}' | xargs -n 2 bash -c 'helm uninstall $0 -n $1'
kubectl get namespaces --no-headers | awk '{print $1}' | grep -vE 'default|kube-system|kube-public|kube-node-lease' | xargs kubectl delete namespace
kubectl delete clusterrole ingress-nginx
kubectl delete namespace ingress-nginx
kubectl delete clusterrolebinding ingress-nginx
kubectl delete clusterrolebinding ingress-nginx-admission
kubectl delete clusterrole ingress-nginx-admission
kubectl delete namespace ingress-nginx --ignore-not-found
kubectl delete ingressclass nginx
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
helm uninstall frappe-bench -n erpnext
kubectl delete storageclass nfs
helm repo remove nfs-ganesha-server-and-external-provisioner
helm repo remove frappe
helm repo remove ingress-nginx
helm repo remove jetstack
helm repo remove frappe_new
helm repo remove nfs-subdir-external-provisioner
helm repo remove bitnami

