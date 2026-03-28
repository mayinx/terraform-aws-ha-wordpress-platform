# Provisions the relational database layer for the platform.
# This module creates a DB subnet group, a database security group,
# and a private Multi-AZ RDS MySQL instance.

# -----------------------------------------------------------------------------
# Data sources
# -----------------------------------------------------------------------------

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# -----------------------------------------------------------------------------
# Local values
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# DB subnet group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Database security group
# -----------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Database access within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL access from within the VPC."
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-db-sg"
  }
}

# -----------------------------------------------------------------------------
# RDS instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier        = "${local.name_prefix}-db"
  engine            = "mysql"
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.db_user
  password          = var.db_password
  port              = 3306

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = true
  publicly_accessible     = false
  storage_encrypted       = true
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "${local.name_prefix}-db"
  }
}