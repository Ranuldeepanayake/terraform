# AWS ECR repository Terraform module

Creates either a private Amazon ECR repository or a public ECR repository. A single module supports both types; the caller sets `repository_type` for each repository. The module's caller must configure both the default AWS provider and the `aws.public` alias. Public ECR is available only in `us-east-1`; the module uses that alias for public repositories while private repositories use the default provider region.

## Features

- Private or public repositories from the same module.
- Private-repository tag mutability, image scanning on push, AES256 or KMS encryption, and non-empty-repository deletion behavior.
- Optional lifecycle policy and private or public repository access policy.
- Optional ECR Public catalog metadata.
- Repository identity, URL, registry ID, type, and tags outputs.

## Requirements

- Terraform 1.16 or later.
- AWS provider 6.55 or later within the `~> 6.55` constraint.
- AWS credentials with permissions for the repository type and configuration being managed.

## Usage

Configure both provider instances in the caller. The public provider must use `us-east-1`:

```hcl
provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "public"
  region = "us-east-1"
}
```

Then pass both providers to the module:

```hcl
module "ecr_repository" {
  source = "../../modules/ecr"

  providers = {
    aws        = aws
    aws.public = aws.public
  }

  repository_type = "private"
  name            = "example/app"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  encryption_type      = "AES256"
  force_delete         = false
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Private repository lifecycle policy

Set `lifecycle_policy` to a JSON-encoded ECR lifecycle policy. For example, this expires untagged images after the ten most recent untagged images:

```hcl
module "ecr_repository" {
  source = "../../modules/ecr"

  providers = {
    aws        = aws
    aws.public = aws.public
  }

  repository_type = "private"
  name            = "example/app"
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the ten most recent untagged images"
      selection = {
        tagStatus   = "untagged"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

Lifecycle policies only apply to private repositories. Review the selection and retention settings carefully: expired images are deleted by ECR and cannot be recovered.

Set `repository_type = "public"` to create an ECR Public repository. Public-repository-only catalog fields can be passed through `catalog_data`:

```hcl
repository_type = "public"
name            = "example-app"
catalog_data = {
  about_text        = "Container images for Example App."
  architectures     = ["ARM", "x86"]
  description       = "Example App images"
  operating_systems = ["Linux"]
  usage_text        = "docker pull public.ecr.aws/example/example-app:latest"
}
```

Public ECR supports neither private-repository encryption/scanning/tag-mutability settings nor lifecycle policies. Keep those inputs at their defaults for public repositories; Terraform will report a precondition error if a private-only option is enabled. `repository_policy` is supported for either type. Public repositories are a separate AWS service resource: changing `repository_type` does not convert an existing repository and will replace the managed resource. Set a valid public repository name when switching types. Repository names, policy documents, catalog metadata, KMS permissions, and provider regions remain subject to AWS service validation.

## Importing existing private repositories

From `aws/module-instances/ecr`, initialize the caller and import the existing `s3-app/backend` and `s3-app/frontend` repositories before running `terraform plan`:

```powershell
terraform init
terraform import 'module.ecr_repositories[\"s3-app-backend\"].aws_ecr_repository.this[0]' 's3-app/backend'
terraform import 'module.ecr_repositories[\"s3-app-frontend\"].aws_ecr_repository.this[0]' 's3-app/frontend'
```

The backslashes preserve the quotes around each `for_each` key when PowerShell invokes Terraform. In other shells, use the normal quoted address, for example `'module.ecr_repositories["s3-app-backend"].aws_ecr_repository.this[0]'`. These addresses match the caller's module keys. Importing manages the ECR repository itself; add separate import commands if you later choose to manage repository policies or lifecycle policies that already exist.
