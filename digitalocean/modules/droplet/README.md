# Droplet Module

This module creates a DigitalOcean Droplet with support for cloud-init user data templates.

## Usage

By default, the module uses the built-in `cloud-init.yaml` template. To use a custom template, provide the `user_data_template` variable with the path to your template file:

```hcl
module "droplet" {
  source = "../modules/droplet"
  # ... other variables ...
  user_data_template = "/absolute/path/to/your-template.yaml"
}
```

- The template file must be compatible with the `templatefile` function and accept the same variables as the default `cloud-init.yaml` (e.g., `docker_user`).

## Variables

- `user_data_template` (string, optional): Path to a custom cloud-init template file. If not set, uses the default `cloud-init.yaml` in the module.

## Default Template Variables

- `docker_user`: The user to add to the Docker group (default: `ubuntu`).

## Example

```hcl
module "droplet" {
  source = "../modules/droplet"
  name   = "example-droplet"
  image  = "ubuntu-22-04-x64"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  # ... other variables ...
  user_data_template = "/path/to/my-cloud-init.yaml"
  docker_user        = "ubuntu"
}
```
