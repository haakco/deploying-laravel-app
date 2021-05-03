# Create a new SSH key
resource "digitalocean_ssh_key" "ssh-key" {
  name = "SSH Key"
  public_key = file("../ansible/roles/deployment/files/deploy_id_ed25519.pub")
}

data "digitalocean_image" "snapshot" {
  name = var.base_web_snapshot_name
}

resource "digitalocean_droplet" "web" {
  name = "srv${format("%02d", count.index)}.${var.dns_domain}"
  size = var.server_size
  image = data.digitalocean_image.snapshot.id
  region = var.region
  ipv6 = true
  ssh_keys = [
    digitalocean_ssh_key.ssh-key.id
  ]
  count = var.server_count
}
