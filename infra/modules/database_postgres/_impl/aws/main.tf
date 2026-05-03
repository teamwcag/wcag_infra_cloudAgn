terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "postgres" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "Postgres security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.name_prefix}-postgres-sg" }, var.tags)
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.name_prefix}-postgres-subnets"
  subnet_ids = var.subnet_ids

  tags = merge({ Name = "${var.name_prefix}-postgres-subnets" }, var.tags)
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.name_prefix}-postgres"
  engine                     = "postgres"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  db_name                    = var.db_name
  username                   = var.username
  password                   = var.password
  port                       = var.port
  db_subnet_group_name       = aws_db_subnet_group.postgres.name
  vpc_security_group_ids     = [aws_security_group.postgres.id]
  multi_az                   = var.multi_az
  publicly_accessible        = false
  storage_encrypted          = true
  deletion_protection        = var.deletion_protection
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = !var.deletion_protection
  apply_immediately          = true
  auto_minor_version_upgrade = true

  tags = merge({ Name = "${var.name_prefix}-postgres" }, var.tags)
}
