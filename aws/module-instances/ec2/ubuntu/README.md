# Ubuntu EC2 caller

This caller deploys an Ubuntu EC2 instance through `aws/modules/ec2-ubuntu`. It is intentionally separate from the Amazon Linux caller in `../common`.

The module supplies the Ubuntu bootstrap (`apt-get`, SSM, EBS mounts, and CloudWatch); `scripts/setup.sh` installs and verifies the Ubuntu packages used by the caller. Review the subnet, region, network rules, and Terraform Cloud workspace before applying.

Run from this directory:

```sh
terraform init
terraform validate
terraform plan
terraform apply
```
