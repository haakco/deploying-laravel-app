data "cloudflare_zones" "dns-domain" {
  filter {
    name = var.dns_domain
  }
}

resource "cloudflare_record" "A-mk" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "km"
  type = "A"
  ttl = var.dns_ttl
  proxied = "false"
  value = digitalocean_kubernetes_cluster.example.ipv4_address
}

//resource "cloudflare_record" "CNAME-mk" {
//  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
//  name = "kend"
//  type = "CNAME"
//  ttl = var.dns_ttl
//  proxied = "false"
//  value = digitalocean_kubernetes_cluster.example.endpoint
//}
