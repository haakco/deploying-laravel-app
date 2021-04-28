variable "do_token" {}

variable region {
  default = "fra1"
}

variable base_web_snapshot_name {
  default = "lv-example-ubuntu-20-04-x64-fra1-20210428185323"
}

variable server_size {
  default = "s-1vcpu-1gb"
}

variable "environment" {
  description = "Enviroment"
  default = "production"
}

variable "server_count" {
  description = "Amount of servers"
  default = 2
}
