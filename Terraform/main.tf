module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  ssh_port           = var.ssh_port
  redis_port         = var.redis_port
  https_port         = var.https_port
  private_cidr_block = var.private_cidr_block
  http_port          = var.http_port
  app_port           = var.app_port
  monitoring_port    = var.monitoring_port
}

output "public_sg" {
  value = module.network.public_sg_id
}

output "private_sg" {
  value = module.network.private_sg_id
}
