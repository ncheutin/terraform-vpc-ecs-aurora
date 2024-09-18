resource "aws_db_subnet_group" "this" {
  name       = "${var.name}_db_subnet_group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier          = var.name
  engine                      = "aurora-mysql"
  engine_mode                 = "provisioned"
  engine_version              = "8.0.mysql_aurora.3.05.2"
  database_name               = var.name
  vpc_security_group_ids      = var.vpc_security_group_ids
  db_subnet_group_name        = aws_db_subnet_group.this.name
  availability_zones          = var.availability_zones
  master_username             = var.db_username
  master_password             = random_password.password.result
  storage_encrypted           = true
  skip_final_snapshot         = true
  tags                        = var.tags

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }

  lifecycle {
    ignore_changes = [
      engine_version,
      master_username,
      master_password,
      availability_zones
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = var.nb_instances
  identifier           = "${var.name}-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.cluster.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.cluster.engine
  engine_version       = aws_rds_cluster.cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.this.name
  tags                 = var.tags
}

resource "aws_secretsmanager_secret" "secret" {
  description = "DB Credentials of ${var.name} service"
  name        = "db/${var.name}-creds"
}

resource "random_password" "password" {
  length           = 40
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "secret" {
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = <<EOF
{
  "username": "${var.db_username}",
  "password": "${random_password.password.result}",
  "engine": "aurora-mysql",
  "host": "${aws_rds_cluster.cluster.endpoint}",
  "port": ${aws_rds_cluster.cluster.port},
  "dbClusterIdentifier": "${aws_rds_cluster.cluster.cluster_identifier}",
  "db" : "${var.name}"
}
EOF
}
