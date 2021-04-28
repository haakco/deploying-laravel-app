# Create a new SSH key
resource "digitalocean_ssh_key" "tim-ssh" {
  name = "Tim SSH Key"
  public_key = file("./ssh_key/timhaak@macbook.pub")
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
    digitalocean_ssh_key.tim-ssh.id
  ]
  count = var.server_count
}
