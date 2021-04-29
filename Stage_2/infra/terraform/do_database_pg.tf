resource "digitalocean_database_cluster" "postgres-cluster" {
  name = var.db_pg_cluster_name
  engine = "pg"
  version = "13"
  size = var.db_size
  region = var.region
  node_count = var.db_pg_node_count
}

resource "digitalocean_database_db" "database-example" {
  cluster_id = digitalocean_database_cluster.postgres-cluster.id
  name = var.db_pg_name
}

resource "digitalocean_database_firewall" "block-external-fw" {
  cluster_id = digitalocean_database_cluster.postgres-cluster.id

  dynamic "rule" {
    for_each = digitalocean_droplet.web
    content {
      type = "droplet"
      value = rule.value["id"]
    }
  }
}
