#--------------------------------------------------
# rds
#--------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.project}-${var.environment}-aurora-cluster"

  engine          = var.engine
  engine_version  = var.engine_version
  master_username = "admin"
  master_password = var.db_password

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "18:00-19:00" # UTC
  preferred_maintenance_window = "wed:19:15-wed:19:45"
  final_snapshot_identifier    = "${var.project}-${var.environment}-finalsnapshot-${formatdate("YYYYMMDDhhmmZZZ", timestamp())}"

  port                            = 3306
  vpc_security_group_ids          = var.security_group_ids
  db_subnet_group_name            = aws_db_subnet_group.this.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  # RDSへの変更を直ちに適用する
  apply_immediately = true

  lifecycle {
    # NOTE: パスワードをTerraformの管理対象外にするため、rds作成後にコンソールから変更する(master_password)
    # NOTE: インスタンス削除時にリソース作成時刻が名前に入ったスナップショットを取るようにしており、都度applyの度に差分検出されるため無視する(final_snapshot_identifier)
    ignore_changes = [master_password, final_snapshot_identifier]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-aurora-cluster"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-rds-cluster-param-group"
  family = var.parameter_group_family

  tags = {
    Name        = "${var.project}-${var.environment}-rds-cluster-param-group"
    Project     = var.project
    Environment = var.environment
  }

  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_filesystem"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = "1"

  identifier         = "${var.project}-${var.environment}-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.this.cluster_identifier

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version
  instance_class = var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name

  tags = {
    Name        = "${var.project}-${var.environment}-aurora-instance-${count.index}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-db-param-group"
  family = var.parameter_group_family

  tags = {
    Name        = "${var.project}-${var.environment}-db-param-group"
    Project     = var.project
    Environment = var.environment
  }
}
