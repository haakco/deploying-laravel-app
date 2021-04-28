data "cloudflare_zones" "dns-domain" {
  filter {
    name = var.dns_domain
  }
}

resource "cloudflare_record" "A-test-dns-domain" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "test"
  type = "A"
  ttl = var.dns_ttl
  proxied = "false"
  value = "127.0.0.1"
}

resource "cloudflare_record" "A-srv00" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "srv${format("%02d", count.index)}.${var.dns_domain}"
  type = "A"
  ttl = var.dns_ttl
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
  count  = length(digitalocean_droplet.web.*.ipv4_address)
}

resource "cloudflare_record" "AAAA-srv00" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "srv${format("%02d", count.index)}.${var.dns_domain}"
  type = "AAAA"
  ttl = var.dns_ttl
  value  = element(digitalocean_droplet.web.*.ipv6_address, count.index)
  count  = length(digitalocean_droplet.web.*.ipv6_address)
}

resource "cloudflare_record" "A-web" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "web"
  type = "A"
  ttl = var.dns_ttl
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}

resource "cloudflare_record" "AAAA-web" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "web"
  type = "AAAA"
  ttl = var.dns_ttl
  count  = length(digitalocean_droplet.web.*.ipv6_address)
  value  = element(digitalocean_droplet.web.*.ipv6_address, count.index)
}

resource "cloudflare_record" "A" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "@"
  type = "A"
  ttl = var.dns_ttl
  proxied = true
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}

resource "cloudflare_record" "A-www" {
  zone_id = data.cloudflare_zones.dns-domain.id
  name = "www"
  type = "A"
  ttl = var.dns_ttl
  proxied = true
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}
