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
