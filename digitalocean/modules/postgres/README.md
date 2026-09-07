# DigitalOcean Postgres Module

This module creates a DigitalOcean PostgreSQL database cluster with firewall rules and no replicas.

## Variables
- `name` (string, required): The name of the database cluster.
- `region` (string, required): The region to create the database in.
- `size` (string, optional): The size/slug of the database cluster. Default: `db-s-1vcpu-1gb`.
- `version` (string, optional): The version of Postgres. Default: `15`.
- `private_network_uuid` (string, optional): The VPC UUID to launch the database in.
- `firewall_rules` (list, optional): List of firewall rules (type/value objects).

## Outputs
- `id`: The database cluster ID.
- `host`: The hostname of the database.
- `port`: The port of the database.
- `user`: The default user.
- `password`: The default user password (sensitive).
- `database`: The default database name.
- `uri`: The connection URI (sensitive).

## Example

```hcl
module "postgres" {
  source = "../modules/postgres"
  name   = "my-db"
  region = "nyc3"
  firewall_rules = [
    { type = "ip_addr", value = "203.0.113.1" },
    { type = "tag", value = "my-app" }
  ]
}
```
