# Secret object.
resource "aws_secretsmanager_secret" "this" {
  name_prefix   = "${var.name}-"
  description = var.description
  kms_key_id  = var.kms_key_id
  tags = merge(
    var.tags,
    {
      ResourceType = "Secret"
    }
  )
}

# Secret content.
resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string

  # Ignore changes to the secret string which will obviously be updated after creation.
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}