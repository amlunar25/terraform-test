resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.tag_name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_a_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_1
  tags = {
    Name = "${var.tag_name}-subnet-public-a"
  }
}

# resource "aws_subnet" "public_b" {
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = var.public_b_subnet_cidr
#   map_public_ip_on_launch = true
#   availability_zone       = var.az_2
#   tags = {
#     Name = "${var.tag_name}-subnet-public-b"
#   }
# }


resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_a_subnet_cidr
  availability_zone = var.az_1
  tags = {
    Name = "${var.tag_name}-subnet-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_b_subnet_cidr
  availability_zone = var.az_2
  tags = {
    Name = "${var.tag_name}-subnet-private-b"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.tag_name}-igw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "${var.tag_name}-nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.tag_name}-public-route-table"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.tag_name}-private-route-table"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
