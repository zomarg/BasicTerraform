variable "location" {
  default = ""
}

variable "domain" {
  default = ""
}

variable "comment" {
  default = ""
}

variable "owner" {
  default = ""
}

variable "public_key" {
  default = ""
}

variable "admin_password" {
}

variable "vms" {
  type    = list(string)
  default = ["vmOne", "vmTwo"]
}
