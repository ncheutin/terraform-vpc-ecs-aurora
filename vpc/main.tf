resource "aws_vpc" "this" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = var.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway == false ? 0 : length(var.private_subnets)

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id, count.index)

  tags = var.tags
  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat" {
  count = length(var.private_subnets)

  domain = "vpc"

  tags = var.tags
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.this.id
  cidr_block = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = var.tags
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.this.id
  cidr_block = element(var.public_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route" "private" {
  count = var.enable_nat_gateway == false ? 0 : length(var.private_subnets)

  route_table_id = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id = element(aws_subnet.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  route_table_id = aws_route_table.public.id
  subnet_id = element(aws_subnet.public.*.id, count.index)
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc-flow-logs-role.arn
  log_destination = aws_cloudwatch_log_group.main.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.stack_name}-cloudwatch-log-group"

  tags = var.tags
}

resource "aws_iam_role" "vpc-flow-logs-role" {
  name = "${var.stack_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "vpc-flow-logs.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc-flow-logs-policy" {
  name = "${var.stack_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc-flow-logs-role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = aws_route_table.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecr-dkr-endpoint" {
  vpc_id       = aws_vpc.this.id
  private_dns_enabled = true
  service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecr-api-endpoint" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecs-agent" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.ecs-agent"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecs-telemetry" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.ecs-telemetry"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}

resource "aws_vpc_endpoint" "cassandra" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.cassandra"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [var.security_group_ecs_task]
  subnet_ids = aws_subnet.private.*.id

  tags = var.tags
}
