# Create a tag for LB
resource "digitalocean_tag" "expose-lb" {
  name = "expose-lb"
}

resource "digitalocean_kubernetes_cluster" "example" {
  name    = var.kubernetes_cluster_name
  region  = var.region
  version = var.kubernetes_version
  auto_upgrade = var.kubernetes_auto_upgrade
  surge_upgrade = var.kubernetes_surge_upgrade

  node_pool {
    name       = var.kubernetes_cluster_autoscale_pool_name
    size       = var.server_size
    auto_scale = var.kubernetes_auto_scale
    min_nodes  = var.kubernetes_min_nodes
    max_nodes  = var.kubernetes_max_nodes
    tags = [digitalocean_tag.expose-lb.id]
  }
}

resource "digitalocean_loadbalancer" "lb01" {
  name = "lb01"
  region = var.region

  forwarding_rule {
    entry_port = 443
    entry_protocol = "https"
    target_port = 443
    target_protocol = "https"
    tls_passthrough = true
  }

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"
    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = var.health_check_port
    protocol = "http"
    path = "/ping"
  }

  droplet_tag = digitalocean_tag.expose-lb.id
}

resource "digitalocean_firewall" "fw-lb01" {
  name = "fw-lb01"

  # Allow healthcheck
  inbound_rule {
    protocol = "tcp"
    port_range = var.health_check_port
    source_addresses   = ["0.0.0.0/0", "::/0"]
  }

  # Allow load balancer traffic / tcp
  inbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    source_load_balancer_uids = [digitalocean_loadbalancer.lb01.id]
  }

  # Allow load balancer traffic / udp
  inbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    source_load_balancer_uids = [digitalocean_loadbalancer.lb01.id]
  }
}
