resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.azs[count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
    App  = var.app
  }
}

resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
    App  = var.app
  }
}
