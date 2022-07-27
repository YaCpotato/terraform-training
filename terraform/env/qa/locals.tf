# tag
locals {
  project     = "prologue-terraform"
  environment = "qa"
}

# network
locals {
  vpc_cidr_block = "10.1.0.0/16"

  public_subnets = {
    ap-northeast-1a = {
      cidr_block = "10.1.0.0/24"
    }
    ap-northeast-1c = {
      cidr_block = "10.1.1.0/24"
    }
  }
  private_subnets = {
    ap-northeast-1a = {
      cidr_block = "10.1.30.0/24"
    }
    ap-northeast-1c = {
      cidr_block = "10.1.31.0/24"
    }
  }
}

# rds
locals {
  rds_engine_version     = "5.7.mysql_aurora.2.10.2"
  parameter_group_family = "aurora-mysql5.7"
  instance_class         = "db.t3.small"
}

# ec2
locals {
  ami_id        = "ami-0561edd51939becb6" # 20220621_prologue-ami
  instance_type = "t2.micro"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

# elasticache
locals {
  node_type                  = "cache.t3.micro"
  elasticache_engine_version = "6.x"
  automatic_failover_enabled = false
  param_group_family         = "redis6.x"
  num_cache_clusters         = 1
  node_count                 = 1
}

# route53, ses
locals {
  domain = "ime-prologue.link"
}

# waf
locals {
  log_bucket_name = "waf-log-qa"
  acl             = "private"
}
