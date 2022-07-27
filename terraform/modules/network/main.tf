#--------------------------------------------------
# vpc
#--------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}

#--------------------------------------------------
# public subnet
#--------------------------------------------------

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-${var.environment}-public-subnet-${each.key}"
    Project     = var.project
    Environment = var.environment
  }
}

# internet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.project}-${var.environment}-public-rtb"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# nat gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public["ap-northeast-1a"].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name        = "${var.project}-${var.environment}-nat-gateway"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name        = "${var.project}-${var.environment}-eip-for-nat-gateway"
    Project     = var.project
    Environment = var.environment
  }
}

#--------------------------------------------------
# private subnet
#--------------------------------------------------

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  tags = {
    Name        = "${var.project}-${var.environment}-private-subnet-${each.key}"
    Project     = var.project
    Environment = var.environment
  }
}

# route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.project}-${var.environment}-private-rtb"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route" "to_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
