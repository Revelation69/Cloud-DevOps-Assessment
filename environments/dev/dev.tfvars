##############
# VPC Variables
###############
vpc_name                     = "Cloud-Devops-Assessment-VPC"
cidr                         = "10.0.0.0/16"
region                       = "us-east-1"
public_subnets               = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets              = ["10.0.3.0/24", "10.0.4.0/24"]
create_database_subnet_group = true
database_subnets             = ["10.0.5.0/24", "10.0.6.0/24"]
database_subnet_group_name   = "db-subnet"
enable_nat_gateway           = true
single_nat_gateway           = true
enable_dns_hostnames         = true
enable_dns_support           = true
tags = {
  Terraform   = "true"
  Environment = "dev"
}

################
# EKS variables
################
cluster_name                    = "Cloud-DevOps-Assessment-eks"
cluster_version                 = "1.28"
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true
cluster_addons = {
  kube-proxy = {}
  vpc-cni    = {}
  coredns    = {}
}

manage_aws_auth_configmap = true
enable_irsa               = true

eks_managed_node_groups = {

  spot = {
    desired_size = 1
    min_size     = 1
    max_size     = 10

    instance_types = ["t2.large"]
    capacity_type  = "ON_DEMAND"
  }

  general = {
    desired_size = 1
    min_size     = 1
    max_size     = 10

    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
  spot = {
    desired_size = 1
    min_size     = 1
    max_size     = 10

    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
  }
}

admin_username     = "Mike"
developer_username = "Ajala"

namespace = "cda"

# ###############
# Database variables
# ###############
identifier           = "database1"
create_db_instance   = true
engine               = "mysql"
engine_version       = "8.0.33"
instance_class       = "db.c6gd.medium"
allocated_storage    = 5
db_name              = "demodb"
port                 = "3306"
family               = "mysql8.0"
major_engine_version = "8.0"
deletion_protection  = false


# ###############
# Security-Group-RDS variables
# ###############
sg-name             = "mysql-rds-sg"
create              = true
ingress_cidr_blocks = []
egress_cidr_blocks  = ["10.0.0.0/16"]
ingress_rules       = [/*"http-80-tcp",*/]
egress_rules        = [/*"http-80-tcp",*/]
ingress_with_cidr_blocks = [
  {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "open port range 3306/tcp ingress rule"
    cidr_blocks = "10.0.0.0/16"
  }
]
egress_with_cidr_blocks = []



################
# Frontend ECR variables
################
frontend_repository_name         = "frontend"
frontend_repository_type         = "private"
frontend_create_lifecycle_policy = false

################
# Backend ECR variables
################
backend_repository_name         = "backend"
backend_repository_type         = "private"
backend_create_lifecycle_policy = false

#####################
# Jenkins-ec2
########################
instance-name = "Jenkins-server"
key-name      = "jenkins"
iam-role      = "Jenkins-iam-role"