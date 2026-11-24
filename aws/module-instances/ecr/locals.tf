locals {
  aws_region = "ap-southeast-1"

  repositories = {
    s3-app-backend = {
      repository_type      = "private"
      name                 = "s3-app/backend"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
      encryption_type      = "AES256"
      kms_key              = null
      force_delete         = true
      lifecycle_policy     = null
      repository_policy    = null
      catalog_data         = null
      # Match the tags already attached to this imported repository.
      tags = {
        project       = "s3-app"
        environment   = "dev"
        resource-type = "container-repository"
      }
    }

    s3-app-frontend = {
      repository_type      = "private"
      name                 = "s3-app/frontend"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
      encryption_type      = "AES256"
      kms_key              = null
      force_delete         = true
      lifecycle_policy     = null
      repository_policy    = null
      catalog_data         = null
      # The existing frontend repository currently has no tags.
      tags = {
        project       = "s3-app"
        environment   = "dev"
        resource-type = "container-repository"
      }
    }
  }
}