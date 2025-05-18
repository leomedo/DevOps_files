# sudo systemctl enable docker
# sudo systemctl restart docker

docker build -t erpnext-zatca:v15 .
docker save erpnext-zatca:v15 -o erpnext-zatca.tar
sudo k3s ctr images import erpnext-zatca.tar
sudo k3s ctr images ls | grep erpnext-zatca


docker build -t my-custom-erpnext:latest .
docker save my-custom-erpnext:latest -o my-custom-erpnext.tar
sudo k3s ctr images import my-custom-erpnext.tar
sudo k3s ctr images ls | grep my-custom-erpnext