# modules/cache/variables.tf

variable "cluster_id" {
  type = string
}

variable "node_type" {
  type    = string
}

variable "num_cache_nodes" {
  type    = number
  default = 1
}

variable "port" {
  type        = number
  description = "Port to allow Redis access"
}

variable "subnet_group_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}
