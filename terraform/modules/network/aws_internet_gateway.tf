resource "aws_internet_gateway" "default_ig" {
  vpc_id = aws_vpc.default_vpc.id
  tags   = local.common_tags
}
