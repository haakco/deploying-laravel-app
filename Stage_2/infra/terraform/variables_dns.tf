variable "dns_domain" {
  description = "Main domain"
  default = "custd.com"
}

variable "dns_mx_ttl" {
  default = "900"
}

variable "dns_ttl" {
  default = "60"
}

variable "dns_site_verification_ttl" {
  default = "60"
}
