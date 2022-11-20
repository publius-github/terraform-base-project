output "vpc_id" {
    value = aws_vpc.default_vpc.id
}

output "subnet_ids" {
    value = aws_subnet.private.*.id
}
