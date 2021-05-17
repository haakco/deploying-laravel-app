//#===K8TESTCLUSTER KUBERNETES===============================================
provider "kubernetes" {
  host = digitalocean_kubernetes_cluster.example.endpoint

  client_certificate     = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.client_certificate)
  client_key             = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
}

#---GENERIC/DASHBOARD USER-------------------------------------------------
# This account has the token we use to get into the dashboard using its permissions
resource "kubernetes_service_account" "dashboard-user" {
  automount_service_account_token = true

  metadata {
    name      = "dashboard-user"
    namespace = "kube-system"
  }
}
resource "kubernetes_cluster_role_binding" "dashboard-user-clusterrolebinding" {
  metadata {
    name = "dashboard-user-clusterrolebinding"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "dashboard-user"
    namespace = "kube-system"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

