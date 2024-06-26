module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 19.16"
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_addons                  = var.cluster_addons
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids 
  enable_irsa                     = var.enable_irsa
  eks_managed_node_groups         = var.eks_managed_node_groups
  manage_aws_auth_configmap       = var.manage_aws_auth_configmap
  aws_auth_roles                  = var.aws_auth_roles
  tags = var.tags
}