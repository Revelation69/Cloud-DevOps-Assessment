module "vpc" {
  source          = "./modules/vpc"
  vpc_name        = var.vpc_name
  cidr            = var.cidr
  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  create_database_subnet_group = var.create_database_subnet_group
  database_subnets             = var.database_subnets
  database_subnet_group_name   = var.database_subnet_group_name
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.tags
}


module "rds" {
  source                     = "./modules/rds"
  identifier                 = var.identifier
  create_db_instance         = var.create_db_instance
  engine                     = var.engine
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  database_subnet_group_name = var.database_subnet_group_name
  allocated_storage          = var.allocated_storage
  vpc_security_group_ids     = module.sg-rds.security_group_id
  db_name                    = var.db_name
  username                   = var.username
  password                   = var.password
  port                       = var.port
  database_subnets           = var.database_subnets
  family                     = var.family
  major_engine_version       = var.major_engine_version
  deletion_protection        = var.deletion_protection
  tags                       = var.tags
}

module "sg-rds" {
  source                   = "./modules/sg"
  vpc_id                   = module.vpc.vpc_id
  create                   = var.create
  ingress_cidr_blocks      = var.ingress_cidr_blocks
  ingress_rules            = var.ingress_rules
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  egress_with_cidr_blocks  = var.egress_with_cidr_blocks
  egress_cidr_blocks       = var.egress_cidr_blocks
  egress_rules             = var.egress_rules
}

module "eks" {
  source                          = "./modules/eks"
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_addons                  = var.cluster_addons
  vpc_id                          = module.vpc.vpc_id
  enable_irsa                     = var.enable_irsa
  subnet_ids                      = module.vpc.private_subnets
  eks_managed_node_groups         = var.eks_managed_node_groups
  manage_aws_auth_configmap       = var.manage_aws_auth_configmap
  aws_auth_roles                  = local.aws_auth_roles
  tags                            = var.tags
}

resource "kubernetes_namespace" "online-boutique" {
  metadata {
    name = "online-boutique"

    labels = {
      managed_by = "terraform"
    }
  }
}

resource "kubernetes_role" "namespace-viewer" {
  metadata {
    name = "namespace-viewer"
    namespace = "online-boutique"
  }

  rule {
    api_groups     = [""]
    resources      = ["pods", "services", "secrets", "configmap", "persistentvolumes"]
    verbs          = ["get", "list", "watch", "describe"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "describe"]
  }
}

resource "kubernetes_role_binding" "namespace-viewer" {
  metadata {
    name      = "namespace-viewer"
    namespace = "online-boutique"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "namespace-viewer"
  }
  subject {
    kind      = "User"
    name      = "developer"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "describe"]
  }

  rule {
    api_groups = [""]
    resources = ["pods/portforward"]
    verbs = ["get", "list", "create"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources = ["customresourcedefinitions"]
    verbs = ["get", "list", "describe"]
  }

  rule {
    api_groups = [""]
    resources = ["pods/exec", "pods/attach"]
    verbs = ["get", "list", "create"]
  }
  
  rule {
    api_groups = [""]
    resources = ["pods"]
    verbs = ["get", "list", "create", "describe", "delete", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = "cluster-viewer"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
}


