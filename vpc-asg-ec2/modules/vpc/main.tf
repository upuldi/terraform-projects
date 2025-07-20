# --- VPC ---

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-vpc"
    App  = var.app
  }
}

# --- Subnets ---

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-${count.index + 1}"
    App  = var.app
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.name}-private-subnet-${count.index + 1}"
    App  = var.app
  }
}

# --- Gateways ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name}-igw"
    App  = var.app
  }
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${count.index + 1}"
    App  = var.app
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}-nat-gw-${count.index + 1}"
    App  = var.app
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- Route Tables & Associations ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name}-public-rt"
    App  = var.app
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)) : 1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
    App  = var.app
  }
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private" {
  count     = length(aws_subnet.private)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? (
    var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  ) : aws_route_table.private[0].id
}

# --- Network ACLs ---

# Public Subnet Network ACL (Default - Allow All)
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.name}-public-nacl"
    App  = var.app
  }
}

# Public NACL Rules - Allow all traffic (standard public subnet behavior)
resource "aws_network_acl_rule" "public_inbound_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "public_outbound_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  egress         = true
}

# Private Subnet Network ACL (Restrictive - Only from Public Subnets)
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.name}-private-nacl"
    App  = var.app
  }
}

# Private NACL Inbound Rules - Only allow traffic from public subnets
resource "aws_network_acl_rule" "private_inbound_from_public" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100 + count.index
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 0
  to_port        = 0
}

# Allow inbound traffic from other private subnets (for internal communication)
resource "aws_network_acl_rule" "private_inbound_from_private" {
  count          = length(var.private_subnet_cidrs)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200 + count.index
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[count.index]
  from_port      = 0
  to_port        = 0
}

# Allow ephemeral ports for return traffic from internet (for NAT Gateway)
resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 300
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow HTTPS return traffic for package updates
resource "aws_network_acl_rule" "private_inbound_https_return" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 310
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow HTTP return traffic for package updates
resource "aws_network_acl_rule" "private_inbound_http_return" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 320
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Private NACL Outbound Rules
# Allow all outbound to public subnets
resource "aws_network_acl_rule" "private_outbound_to_public" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100 + count.index
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 0
  to_port        = 0
  egress         = true
}

# Allow outbound to other private subnets
resource "aws_network_acl_rule" "private_outbound_to_private" {
  count          = length(var.private_subnet_cidrs)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200 + count.index
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[count.index]
  from_port      = 0
  to_port        = 0
  egress         = true
}

# Allow outbound HTTPS for package updates and SSM
resource "aws_network_acl_rule" "private_outbound_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 300
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
  egress         = true
}

# Allow outbound HTTP for package updates
resource "aws_network_acl_rule" "private_outbound_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 310
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
  egress         = true
}

# Allow outbound ephemeral ports for return traffic
resource "aws_network_acl_rule" "private_outbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 320
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
  egress         = true
}

# Allow outbound DNS
resource "aws_network_acl_rule" "private_outbound_dns_tcp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 330
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}

resource "aws_network_acl_rule" "private_outbound_dns_udp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 340
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}
