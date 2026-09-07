module "internet_gateway" {
  source = "../../modules/internet-gateway"

  vpc_id = var.vpc_id
  tags = merge(
    {
      type = "internet-gateway"
    },
    var.tags
  )
}