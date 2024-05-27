module "vpc" {
  source                       = "./modules/vpc"
  vpc_name                     = var.vpc_name
  cidr                         = var.cidr
  azs                          = ["${var.region}a", "${var.region}b"]
  private_subnets              = var.private_subnets
  public_subnets               = var.public_subnets
  create_database_subnet_group = var.create_database_subnet_group
  database_subnets             = var.database_subnets
  database_subnet_group_name   = var.database_subnet_group_name
  enable_nat_gateway           = var.enable_nat_gateway
  single_nat_gateway           = var.single_nat_gateway
  enable_dns_hostnames         = var.enable_dns_hostnames
  enable_dns_support           = var.enable_dns_support
  tags                         = var.tags
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
  iam_role_additional_policies    = local.iam_role_additional_policies
  tags                            = var.tags
}

module "ecr" {
  source                           = "./modules/ecr"
  frontend_repository_name         = var.frontend_repository_name
  frontend_repository_type         = var.frontend_repository_type
  frontend_create_lifecycle_policy = var.frontend_create_lifecycle_policy
  backend_repository_name          = var.backend_repository_name
  backend_repository_type          = var.backend_repository_type
  backend_create_lifecycle_policy  = var.backend_create_lifecycle_policy
  tags                             = var.tags
}


resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = "t2.2xlarge"
  key_name               = var.key-name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 30
  }
  user_data = templatefile("./tools-install.sh", {})

  tags = {
    Name = var.instance-name
  }
}

resource "aws_security_group" "security-group" {
  vpc_id      = module.vpc.vpc_id
  description = "Allowing Jenkins,  SSH Access"

  ingress = [
    for port in [22, 8080, 9000, 9090, 80] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-name
  }
}


resource "kubernetes_namespace" "cda" {
  metadata {
    name = "cda"

    labels = {
      managed_by = "terraform"
    }
  }
}

resource "kubernetes_role" "namespace-viewer" {
  metadata {
    name      = "namespace-viewer"
    namespace = "cda"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "configmap", "persistentvolumes"]
    verbs      = ["get", "list", "watch", "describe"]
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
    namespace = "cda"
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
    resources  = ["pods/portforward"]
    verbs      = ["get", "list", "create"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "describe"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec", "pods/attach"]
    verbs      = ["get", "list", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "create", "describe", "delete", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-viewer"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
}


