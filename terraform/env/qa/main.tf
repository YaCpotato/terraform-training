#--------------------------------------------------
# network
#--------------------------------------------------

module "network" {
  source = "../../modules/network"

  vpc_cidr_block  = local.vpc_cidr_block
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  project     = local.project
  environment = local.environment
}

#--------------------------------------------------
# route53
#--------------------------------------------------

module "route53" {
  source = "../../modules/route53"

  for_each = toset(["dev", "stg"])

  domain     = local.domain
  sub_domain = "${each.value}.${local.domain}"

  project     = local.project
  environment = "${local.environment}-${each.value}"
}

#--------------------------------------------------
# elb
#--------------------------------------------------

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "elb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  use_name_prefix = false
  name            = "${local.project}-${local.environment}-sg-elb"
  description     = "security group for elb"
  vpc_id          = lookup(module.network.this, "vpc_id")

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "allow-http-from-internet"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "allow-https-from-internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = ""
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "${local.project}-${local.environment}-sg-elb"
    Project     = local.project
    Environment = local.environment
  }
}

module "elb" {
  source = "../../modules/elb"

  for_each = toset(["dev", "stg"])

  vpc_id    = lookup(module.network.this, "vpc_id")
  target_id = module.ec2[each.value].ec2_id
  subnet_ids = [
    lookup(module.network.this, "public_1a_id"),
    lookup(module.network.this, "public_1c_id")
  ]
  security_group_ids = [module.elb_security_group.security_group_id]

  # route53にelbのレコードを登録
  route53_zone_id = module.route53[each.value].sub_domain_zone_id
  route53_name    = module.route53[each.value].sub_domain_name

  # httpsリスナーへの証明書アタッチ
  certificate_arn = module.route53[each.value].certificate_arn

  deletion_protection = false # 削除保護

  project     = local.project
  environment = "${local.environment}-${each.value}"
}

#--------------------------------------------------
# ec2
#--------------------------------------------------

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  use_name_prefix = false
  name            = "${local.project}-${local.environment}-sg-ec2"
  description     = "security group for private ec2"
  vpc_id          = lookup(module.network.this, "vpc_id")

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "allow-ingress-from-elb"
      source_security_group_id = module.elb_security_group.security_group_id
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = ""
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "${local.project}-${local.environment}-sg-ec2"
    Project     = local.project
    Environment = local.environment
  }
}

module "ec2" {
  source = "../../modules/ec2"

  for_each = toset(["dev", "stg"])

  ami_id             = local.ami_id
  subnet_id          = lookup(module.network.this, "private_1a_id")
  security_group_ids = [module.ec2_security_group.security_group_id]
  instance_type      = local.instance_type

  iam_role_policy_arns = local.policy_arns

  deletion_protection = false # 削除保護

  project     = local.project
  environment = "${local.environment}-${each.value}"
}

#--------------------------------------------------
# rds
#--------------------------------------------------

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  use_name_prefix = false
  name            = "${local.project}-${local.environment}-sg-rds"
  description     = "security group for rds"
  vpc_id          = lookup(module.network.this, "vpc_id")

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "allow-ingress-from-ec2"
      source_security_group_id = module.ec2_security_group.security_group_id
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = ""
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "${local.project}-${local.environment}-sg-rds"
    Project     = local.project
    Environment = local.environment
  }
}

module "rds" {
  source = "../../modules/rds"

  subnet_ids = [
    lookup(module.network.this, "private_1a_id"),
    lookup(module.network.this, "private_1c_id")
  ]
  engine_version         = local.rds_engine_version
  security_group_ids     = [module.rds_security_group.security_group_id]
  parameter_group_family = local.parameter_group_family
  instance_class         = local.instance_class
  deletion_protection    = false # 削除保護
  skip_final_snapshot    = true

  db_password = var.db_password

  project     = local.project
  environment = local.environment
}

#--------------------------------------------------
# elasticache
#--------------------------------------------------

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "elasticache_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  use_name_prefix = false
  name            = "${local.project}-${local.environment}-sg-elasticache"
  description     = "security group for elasticache"
  vpc_id          = lookup(module.network.this, "vpc_id")

  ingress_with_source_security_group_id = [
    {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      description              = "allow-ingress-from-ec2"
      source_security_group_id = module.ec2_security_group.security_group_id
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = ""
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "${local.project}-${local.environment}-sg-elasticache"
    Project     = local.project
    Environment = local.environment
  }
}

module "elasticache" {
  source = "../../modules/elasticache"

  subnet_ids = [
    lookup(module.network.this, "private_1a_id"),
    lookup(module.network.this, "private_1c_id")
  ]
  security_group_ids = [module.elasticache_security_group.security_group_id]

  node_type                  = local.node_type
  engine_version             = local.elasticache_engine_version
  automatic_failover_enabled = local.automatic_failover_enabled
  num_cache_clusters         = local.num_cache_clusters
  param_group_family         = local.param_group_family
  node_count                 = local.node_count

  project     = local.project
  environment = local.environment
}

#--------------------------------------------------
# waf
#--------------------------------------------------

module "s3_waf_log" {
  source = "../../modules/s3"

  bucket_name = local.log_bucket_name
  acl         = local.acl

  enable_delete_lifecycle = true

  project     = local.project
  environment = local.environment
}

module "kinesis_for_waf_log" {
  source = "../../modules/kinesis-data-firehose"

  bucket_arn = module.s3_waf_log.bucket_arn

  project     = local.project
  environment = local.environment
}

module "waf" {
  source = "../../modules/waf"

  # wafはdev/stgの共有リソースとしてelbにアタッチ
  elb_arns = {
    dev = module.elb["dev"].elb_arn,
    stg = module.elb["stg"].elb_arn
  }
  log_destination_arns = [module.kinesis_for_waf_log.firehose_arn]

  project     = local.project
  environment = local.environment
}

#--------------------------------------------------
# ses
#--------------------------------------------------

module "ses" {
  source = "../../modules/ses"

  for_each = toset(["dev", "stg"])

  domain          = "${each.value}.${local.domain}"
  route53_zone_id = module.route53[each.value].sub_domain_zone_id

  project     = local.project
  environment = local.environment
}
