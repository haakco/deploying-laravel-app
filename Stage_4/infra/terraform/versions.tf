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

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.2"
    }

    helm = {
      source = "hashicorp/helm"
      version = "~> 2.1"
    }
  }

  required_version = "~> 0.15"
}

