variable "do_token" {
  type      = string
  sensitive = true
}

variable "ssh_keys" {
  type = list(string)
}