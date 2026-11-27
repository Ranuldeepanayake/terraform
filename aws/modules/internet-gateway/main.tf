resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    var.name == null ? {} : {
      Name = var.name
    },
    {
      ResourceType = "internet-gateway"
    }
  )
}