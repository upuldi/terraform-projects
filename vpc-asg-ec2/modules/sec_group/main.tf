resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id
  tags        = var.tags

  # Prevent creation of default rules, allowing them to be managed exclusively
  # by the aws_vpc_security_group_ingress_rule and egress_rule resources.
  ingress = []
  egress  = []
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  description       = each.value.description

  cidr_ipv4                    = lookup(each.value, "cidr_block", null)
  referenced_security_group_id = lookup(each.value, "referenced_sg_id", null)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  description       = each.value.description

  cidr_ipv4                    = lookup(each.value, "cidr_block", null)
  referenced_security_group_id = lookup(each.value, "referenced_sg_id", null)
}
