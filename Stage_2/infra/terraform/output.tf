output "dns_domain" {
  description = "DNS Name for destroy"
  value       = var.dns_domain
}

output "web01-ipv4" {
  value = digitalocean_droplet.web.*.ipv4_address
}

output "web01-ipv6" {
  value = digitalocean_droplet.web.*.ipv6_address
}

output "db-host-private" {
  value = digitalocean_database_cluster.postgres-cluster.private_host
}

output "db-database" {
  value = digitalocean_database_cluster.postgres-cluster.database
}

output "db-port" {
  value = digitalocean_database_cluster.postgres-cluster.port
}

output "db-user" {
  value = digitalocean_database_cluster.postgres-cluster.user
}

output "db-password" {
  value = digitalocean_database_cluster.postgres-cluster.password
  sensitive = true
}

output "db-redis-private-host" {
  value = digitalocean_database_cluster.redis-cluster.private_host
}

output "db-redis-database" {
  value = digitalocean_database_cluster.redis-cluster.database
}

output "db-redis-port" {
  value = digitalocean_database_cluster.redis-cluster.port
}

output "db-redis-user" {
  value = digitalocean_database_cluster.redis-cluster.user
}

output "db-redis-password" {
  value = digitalocean_database_cluster.redis-cluster.password
  sensitive = true
}

data "template_file" "env" {
  template = file("./templates/env.tpl")
  vars = {
    db-host = digitalocean_database_cluster.postgres-cluster.private_host
    db-database = digitalocean_database_cluster.postgres-cluster.database
    db-port = digitalocean_database_cluster.postgres-cluster.port
    db-user = digitalocean_database_cluster.postgres-cluster.user
    db-password = digitalocean_database_cluster.postgres-cluster.password

    db-redis-host = digitalocean_database_cluster.redis-cluster.private_host
    db-redis-port = digitalocean_database_cluster.redis-cluster.port
    db-redis-password = digitalocean_database_cluster.redis-cluster.password
  }
}

output "env" {
  value = data.template_file.env.rendered
}
