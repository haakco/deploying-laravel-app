terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.20"
    }

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.8"
    }
  }

  required_version = "~> 0.15"
}

