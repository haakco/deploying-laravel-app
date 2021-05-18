data "cloudflare_zones" "dns-domain" {
  filter {
    name = var.dns_domain
  }
}

resource "cloudflare_record" "A-dev" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "dev"
  type = "A"
  ttl = var.dns_ttl
  proxied = "false"
  value = "127.0.0.1"
}

resource "cloudflare_record" "A-star-dev" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "*.dev"
  type = "A"
  ttl = var.dns_ttl
  proxied = "false"
  value = "127.0.0.1"
}
