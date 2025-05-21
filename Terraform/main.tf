module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  ssh_port           = var.ssh_port
  redis_port         = var.redis_port
  https_port         = var.https_port
  private_cidr_block = var.private_cidr_block
}

module "static_web" {
  source          = "./modules/static_web"
  bucket_name     = var.bucket_name
  team_user_arns  = var.team_user_arns
  cloudfront_arn  = var.cloudfront_arn
}

module "cache" {
  source             = "./modules/cache"
  cluster_id         = var.cluster_id
  node_type          = var.node_type
  num_cache_nodes    = var.num_cache_nodes
  port               = var.redis_port
  subnet_group_name  = var.subnet_group_name
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.network.private_sg_id]
}

output "public_sg" {
  value = module.network.public_sg_id
}

output "private_sg" {
  value = module.network.private_sg_id
}
