#Common variables.
variable "do_token" {
  type      = string
  sensitive = true
}

variable "tag_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "alert_email" {
  type = list(string)
}