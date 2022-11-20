resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.default_ig]
  count      = var.az_count
  vpc        = true
}

resource "aws_nat_gateway" "nat_gw" {
  depends_on    = [aws_internet_gateway.default_ig]
  count         = var.az_count
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
}
