# Create private repositories with configurable scanning, mutability, encryption, and deletion.
resource "aws_ecr_repository" "this" {
  count = var.repository_type == "private" ? 1 : 0

  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key
  }

  lifecycle {
    precondition {
      condition     = var.encryption_type != "KMS" || var.kms_key != null
      error_message = "Set kms_key when encryption_type is KMS."
    }
  }
}

# ECR Public is hosted in us-east-1, independently of the caller's private ECR region.
resource "aws_ecrpublic_repository" "this" {
  provider = aws.public
  count    = var.repository_type == "public" ? 1 : 0

  repository_name = var.name
  tags            = var.tags

  dynamic "catalog_data" {
    for_each = var.catalog_data == null ? [] : [var.catalog_data]
    content {
      about_text        = catalog_data.value.about_text
      architectures     = catalog_data.value.architectures
      description       = catalog_data.value.description
      logo_image_blob   = catalog_data.value.logo_image_blob
      operating_systems = catalog_data.value.operating_systems
      usage_text        = catalog_data.value.usage_text
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.image_tag_mutability == "MUTABLE" &&
        !var.scan_on_push &&
        var.encryption_type == "AES256" &&
        var.kms_key == null &&
        !var.force_delete &&
        var.lifecycle_policy == null
      )
      error_message = "Image mutability, scanning, encryption, force_delete, and lifecycle policies are private-repository options; use their defaults for a public repository."
    }
  }
}

# Lifecycle policies are supported for private repositories only.
resource "aws_ecr_lifecycle_policy" "this" {
  count = var.repository_type == "private" && var.lifecycle_policy != null ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy     = var.lifecycle_policy
}

# Repository policies may be attached to either private or public repositories.
resource "aws_ecr_repository_policy" "private" {
  count = var.repository_type == "private" && var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy     = var.repository_policy
}

resource "aws_ecrpublic_repository_policy" "public" {
  provider = aws.public
  count    = var.repository_type == "public" && var.repository_policy != null ? 1 : 0

  repository_name = aws_ecrpublic_repository.this[0].repository_name
  policy          = var.repository_policy
}
