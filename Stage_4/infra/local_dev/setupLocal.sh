#!/usr/bin/env bash
kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
helm install \
  --namespace kube-system \
  kubernetes-dashboard \
  kubernetes-dashboard/kubernetes-dashboard \
  --version v0.2.0

#kubectl describe secret $(kubectl get secrets | grep 'dashboard-admin' | awk '{print $1}')
#kubectl proxy &
#open "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:https/proxy/#/login"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install metrics-server bitnami/metrics-server \
  --namespace kube-system \
  --set rbac.create=true \
  --set apiService.create=true \
  --set extraArgs.kubelet-insecure-tls=true \
  --version v0.4.4

helm uninstall \
  --namespace kube-system \
  metrics-server

kubectl create namespace cert-manager

kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
helm install \
  --namespace cert-manager \
  cert-manager \
  jetstack/cert-manager \
  --version v1.1.1 \
  --set installCRDs=true

kubectl --namespace cert-manager apply -f ./cloudflare-apikey-secret.yaml
kubectl --namespace cert-manager apply -f ./cert/acme-production.yaml
kubectl --namespace cert-manager apply -f ./cert/acme-staging.yaml

kubectl create namespace wave
kubectl --namespace wave apply -f ./cert/dev-wave-cert-staging.yaml
kubectl --namespace wave delete -f ./cert/dev-wave-cert-staging.yaml

kubectl create namespace external-dns
kubectl --namespace external-dns apply -f ./cloudflare-apikey-secret.yaml
#kubectl --namespace external-dns delete -f ./cloudflare-apikey-secret.yaml

helm install external-dns \
  --namespace external-dns \
  --set provider=cloudflare \
  --set domainFilters={custd.com} \
  --set cloudflare.proxied=true \
  --set cloudflare.secretName=cloudflare-apikey \
  bitnami/external-dns



#helm uninstall external-dns \
#  --namespace external-dns

#  \ # (optional) enable the proxy feature of Cloudflare (DDOS protection, CDN...)
