#===K8TESTCLUSTER HELM=======================================================
# initialize Helm provider
provider "helm" {
  kubernetes {
    host = digitalocean_kubernetes_cluster.example.endpoint
    client_certificate     = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.client_certificate)
    client_key             = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
  }
}
