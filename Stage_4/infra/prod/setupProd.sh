

#kubectl create namespace external-dns
#kubectl delete namespace external-dns
#kubectl --namespace external-dns apply -f ./cloudflare-apikey-secret.yaml
#kubectl --namespace external-dns delete -f ./cloudflare-apikey-secret.yaml

#helm install \
#  external-dns bitnami/external-dns \
#  --namespace external-dns \
#  --version 5.0.0 \
#  --set provider=cloudflare \
#  --set domainFilters={$DOMAIN} \
#  --set cloudflare.proxied=true \
#  --set cloudflare.secretName=cloudflare-apikey \
#
#
#helm uninstall external-dns \
#  --namespace external-dns
