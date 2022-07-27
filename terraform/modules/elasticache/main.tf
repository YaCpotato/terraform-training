#--------------------------------------------------
# elasticache
#--------------------------------------------------

// cluster
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project}-${var.environment}-elasticache"
  description          = "${var.project}-${var.environment}-elasticache"

  node_type                  = var.node_type
  engine_version             = var.engine_version
  automatic_failover_enabled = var.automatic_failover_enabled
  num_cache_clusters         = var.num_cache_clusters

  subnet_group_name           = aws_elasticache_subnet_group.this.name
  preferred_cache_cluster_azs = ["ap-northeast-1a"]
  parameter_group_name        = aws_elasticache_parameter_group.this.name

  security_group_ids = var.security_group_ids
  port               = 6379

  lifecycle {
    # elasticacheはnum_cache_clustersの数を基準にノードを保持している。
    # レプリカ作成後、tfstateにvar.enum_cache_clustersとvar.node_countを合わせた数がnum_cache_clustersとして保存される。
    # 一方、.tfファイル上のenum_cache_clustersの数は固定なので、次回のapplyでtfstateとの差分と見なされ、var.node_countの数分ノードが削除されてしまう。
    # そのためignore_changesを指定することで、tfstateのnum_cache_clustersを基準に処理させるようにする。
    ignore_changes = [num_cache_clusters]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-elasticache-cluster"
    Project     = var.project
    Environment = var.environment
  }
}

// read replica
resource "aws_elasticache_cluster" "replica" {
  count = var.node_count

  cluster_id           = "${var.project}-${var.environment}-elasticache-replica-${count.index}"
  replication_group_id = aws_elasticache_replication_group.this.id
  availability_zone    = "ap-northeast-1a"

  tags = {
    Name        = "${var.project}-${var.environment}-elasticache-replica-${count.index}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.project}-${var.environment}-elasticache-params"
  description = "${var.project}-${var.environment}-elasticache-params"
  family      = var.param_group_family

  tags = {
    Name        = "${var.project}-${var.environment}-elasticache-params"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.project}-${var.environment}-elasticache-subnet-group"
  description = "${var.project}-${var.environment}-elasticache-subnet-group"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-elasticache-subnet-group"
    Project     = var.project
    Environment = var.environment
  }
}
