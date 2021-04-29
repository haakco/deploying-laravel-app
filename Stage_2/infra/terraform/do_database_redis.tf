resource "digitalocean_database_cluster" "redis-cluster" {
  name       = var.db_redis_cluster_name
  engine     = "redis"
  version    = "6"
  size       = var.db_size
  region     = var.region
  node_count = var.db_redis_node_count
}

resource "digitalocean_database_firewall" "block-external-fw-redis-pg" {
  cluster_id = digitalocean_database_cluster.redis-cluster.id

  dynamic "rule" {
    for_each = digitalocean_droplet.web
    content {
      type = "droplet"
      value = rule.value["id"]
    }
  }
}
