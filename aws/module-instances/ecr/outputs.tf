# Expose a keyed summary of every repository managed by this caller.
output "repositories" {
  description = "Repository identity, URL, type, and registry ID keyed by the local repository key."
  value = {
    for key, repository in module.ecr_repositories : key => {
      name        = repository.repository_name
      arn         = repository.repository_arn
      url         = repository.repository_url
      registry_id = repository.registry_id
      type        = repository.repository_type
      tags        = repository.tags
    }
  }
}
