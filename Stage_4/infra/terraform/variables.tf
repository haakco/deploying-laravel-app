variable "do_token" {}

variable "cf_api_key" {}

variable region {
  default = "fra1"
}

variable kubernetes_version {
  default = "1.20.2-do.0"
}

variable kubernetes_auto_upgrade {
  default = true
}

variable kubernetes_cluster_name {
  default = "example"
}

variable kubernetes_cluster_autoscale_pool_name {
  default = "autoscale-worker-pool"
}

variable server_size {
  default = "s-2vcpu-4gb"
}

variable kubernetes_auto_scale {
  default = true
}

variable kubernetes_surge_upgrade {
  default = true
}

variable kubernetes_min_nodes {
  default = 2
}

variable kubernetes_max_nodes {
  default = 5
}

variable "environment" {
  description = "Enviroment"
  default = "production"
}

# set health check port
variable "health_check_port" {
  default = 8000
}
