output "dns_domain" {
  description = "DNS Name for destroy"
  value       = var.dns_domain
}

output "kube-master-ipv4" {
  value = digitalocean_kubernetes_cluster.example.ipv4_address
}

output "kube-endpoint" {
  value = digitalocean_kubernetes_cluster.example.endpoint
}

output "kube-config" {
  value = digitalocean_kubernetes_cluster.example.kube_config.0
  sensitive = true
}

output "kube-id" {
  value = digitalocean_kubernetes_cluster.example.id
}

data "template_file" "kube_doct_config" {
  template = file("./templates/doct_kube_config.tpl")
  vars = {
    kube-id = digitalocean_kubernetes_cluster.example.id
  }
}

output "kube_doct_config" {
  value = data.template_file.kube_doct_config.rendered
}
