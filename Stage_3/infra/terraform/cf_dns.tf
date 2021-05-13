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

resource "cloudflare_record" "A-srv00" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "srv${format("%02d", count.index)}.${var.dns_domain}"
  type = "A"
  ttl = var.dns_ttl
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
  count  = length(digitalocean_droplet.web.*.ipv4_address)
}

resource "cloudflare_record" "AAAA-srv00" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "srv${format("%02d", count.index)}.${var.dns_domain}"
  type = "AAAA"
  ttl = var.dns_ttl
  value  = element(digitalocean_droplet.web.*.ipv6_address, count.index)
  count  = length(digitalocean_droplet.web.*.ipv6_address)
}

resource "cloudflare_record" "A" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "@"
  type = "A"
//  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}

resource "cloudflare_record" "A-www" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "www"
  type = "A"
//  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}

resource "cloudflare_record" "AAAA" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "@"
  type = "AAAA"
//  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv6_address)
  value  = element(digitalocean_droplet.web.*.ipv6_address, count.index)
}

resource "cloudflare_record" "AAAA-www" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "www"
  type = "AAAA"
//  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv6_address)
  value  = element(digitalocean_droplet.web.*.ipv6_address, count.index)
}

resource "cloudflare_record" "A-traefik" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "traefik"
  type = "A"
  //  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}

resource "cloudflare_record" "A-rediscommander" {
  zone_id = lookup(data.cloudflare_zones.dns-domain.zones[0], "id")
  name = "rediscommander"
  type = "A"
  //  ttl = var.dns_ttl
  proxied = false
  count  = length(digitalocean_droplet.web.*.ipv4_address)
  value  = element(digitalocean_droplet.web.*.ipv4_address, count.index)
}
