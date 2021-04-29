variable "do_token" {}

variable "cf_api_key" {}

variable region {
  default = "fra1"
}

variable db_size {
  default = "db-s-1vcpu-1gb"
}

variable db_pg_cluster_name {
  default = "pg-example"
}

variable db_pg_name {
  default = "pg_example"
}

variable db_pg_node_count {
  default = 1
}

variable db_redis_cluster_name {
  default = "redis-example"
}

variable db_redis_name {
  default = "redis_example"
}

variable db_redis_node_count {
  default = 1
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
