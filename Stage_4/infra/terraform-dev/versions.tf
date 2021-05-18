terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.20"
    }
  }

  required_version = "~> 0.15"
}

