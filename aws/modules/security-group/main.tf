resource "aws_security_group" "security_group" {
  name        = "${var.security_group_name}-${var.subnet_id}"
  description = "${var.security_group_name}-${var.subnet_id}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.security_group_name}-${var.subnet_id}"
    resource-type = "security-group"
  }
}

# Security group rule creation should happen after creating the security group itself first.
resource "aws_security_group_rule" "allow_ssh" {
  description = "Allow SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::0/0"]
  #prefix_list_ids   = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  security_group_id = aws_security_group.security_group.id

  depends_on = [ aws_security_group.security_group ]
}