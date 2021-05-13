variable "do_token" {}

variable "cf_api_key" {}

variable region {
  default = "fra1"
}

variable base_web_snapshot_name {
  default = "lv-example-docker-ubuntu-20-04-x64-fra1-20210513131447"
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
  default = 1
}
