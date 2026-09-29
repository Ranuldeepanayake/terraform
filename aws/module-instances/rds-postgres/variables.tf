###############################################################################
# Database credentials
###############################################################################

variable "db_password" {
  description = "Master password for the PostgreSQL database."
  type        = string
  sensitive   = true
}