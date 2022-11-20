resource "aws_network_acl" "default_networg_acl" {
  count  = var.az_count
  vpc_id = aws_vpc.default_vpc.id

  subnet_ids = [
    "${element(aws_subnet.private.*.id, count.index)}",
    "${element(aws_subnet.public.*.id, count.index)}",
  ]

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = local.common_tags
}
