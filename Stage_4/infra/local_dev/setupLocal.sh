#!/usr/bin/env bash
kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
helm install \
  kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kube-system \
  --version 4.1.0

#kubectl describe secret $(kubectl get secrets | grep 'dashboard-admin' | awk '{print $1}')
#kubectl proxy &
#open "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:https/proxy/#/login"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install \
  metrics-server bitnami/metrics-server \
  --namespace kube-system \
  --version v5.8.7 \
  --set rbac.create=true \
  --set apiService.create=true \
  --set extraArgs.kubelet-insecure-tls=true

#helm uninstall \
#  --namespace kube-system \
#  metrics-server

kubectl create namespace cert-manager
#kubectl delete namespace cert-manager

kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version 1.3.1 \
  --set installCRDs=true \
  --set prometheus.enabled=true \
  --set prometheus.servicemonitor.enabled=true

#helm uninstall \
#  --namespace cert-manager \
#  cert-manager

kubectl --namespace cert-manager apply -f ./cloudflare-apikey-secret.yaml
kubectl --namespace cert-manager apply -f ./cert/acme-production.yaml
kubectl --namespace cert-manager apply -f ./cert/acme-staging.yaml

#kubectl --namespace cert-manager delete -f ./cloudflare-apikey-secret.yaml
#kubectl --namespace cert-manager delete -f ./cert/acme-production.yaml
#kubectl --namespace cert-manager delete -f ./cert/acme-staging.yaml

helm repo add traefik https://containous.github.io/traefik-helm-chart
helm repo update
kubectl create namespace traefik
helm install \
  traefik traefik/traefik \
  --namespace traefik \
  --version 9.1.1 \
  --values ./traefik/traefik-values.yaml

#helm uninstall helm install \
#  -n traefik traefik

kubectl apply -f ./traefik/dev-traefik-cert.yaml
#kubectl delete -f ./traefik/dev-traefik-cert.yaml

export TRAEFIK_USERNAME='traefik'
export TRAEFIK_PASSWD='yairohchahKoo0haem0d'

TRAEFIK_AUTH=$(docker run --rm -ti xmartlabs/htpasswd "traefik" "yairohchahKoo0haem0d" | openssl base64 -A)
export TRAEFIK_AUTH

cat ./traefik/traefik-ingres.tmpl.yaml | envsubst > ./traefik/traefik-ingres.yaml
kubectl apply -f ./traefik/traefik-ingres.yaml
#kubectl delete -f ./traefik/traefik-ingres.yaml

kubectl create namespace wave
kubectl --namespace wave apply -f ./cert/dev-wave-cert-staging.yaml
#kubectl --namespace wave delete -f ./cert/dev-wave-cert-staging.yaml

#kubectl create namespace external-dns
#kubectl delete namespace external-dns
#kubectl --namespace external-dns apply -f ./cloudflare-apikey-secret.yaml
#kubectl --namespace external-dns delete -f ./cloudflare-apikey-secret.yaml

#helm install \
#  external-dns bitnami/external-dns \
#  --namespace external-dns \
#  --version 5.0.0 \
#  --set provider=cloudflare \
#  --set domainFilters={custd.com} \
#  --set cloudflare.proxied=true \
#  --set cloudflare.secretName=cloudflare-apikey \
#
#
#helm uninstall external-dns \
#  --namespace external-dns


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

#https://www.digitalocean.com/community/tutorials/how-to-set-up-digitalocean-kubernetes-cluster-monitoring-with-helm-and-prometheus-operator
#http://www.dcasati.net/posts/installing-prometheus-on-kubernetes-v1.16.9/
#https://docs.syseleven.de/metakube/en/metakube-accelerator/building-blocks/observability-monitoring/kube-prometheus-stack
kubectl create namespace monitoring
#kubectl delete namespace monitoring

helm install \
  prometheus-operator prometheus-community/kube-prometheus-stack\
  --namespace monitoring \
  --version 15.4.6 \
  -f ./prometheus/prometheus-values.yaml
#helm uninstall prometheus-operator --namespace monitoring
