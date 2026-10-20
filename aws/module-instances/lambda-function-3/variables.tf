# Pass in a set of secret values. The caller will encode it to json.
variable "secret_values" {
  type      = map(string)
  sensitive = true
}