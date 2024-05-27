## Policy to allow full EKS access for admin
module "eks_admin_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access-admin"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["eks:DescribeCluster"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

## Policy to allow limited access to EKS for Developers
module "eks_developer_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access-developer"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["eks:DescribeCluster"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


## IAM Role that will be used by admin to access the cluster
module "eks_admins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.eks_admin_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

## IAM Role that will be used by developers to access the cluster 
module "eks_developer_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-developer"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.eks_developer_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

## IAM policy to assume the IAM role for admin
module "allow_assume_eks_admins_iam_policy" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "5.3.1"
  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

## IAM policy to assume the IAM role for developers
module "allow_assume_eks_developer_iam_policy" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "5.3.1"
  name          = "allow-assume-eks-developer-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_developer_iam_role.iam_role_arn
      },
    ]
  })
}


## Create Admin users to access the cluster
module "admin_user" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  version                       = "5.3.1"
  name                          = var.admin_username
  create_iam_access_key         = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}

## Create Developer users to access the cluster
module "developer_user" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  version                       = "5.3.1"
  name                          = var.developer_username
  create_iam_access_key         = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}

## Create an IAM group with users and attach assume policy
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = [module.admin_user.iam_user_name]
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}

module "eks_developer_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-developer"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = [module.developer_user.iam_user_name]
  custom_group_policy_arns          = [module.allow_assume_eks_developer_iam_policy.arn]
}

resource "aws_iam_role_policy_attachment" "iam-policy" {
  role = aws_iam_role.iam-role.name
  # Just for testing purpose, don't try to give administrator access
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}



resource "aws_iam_role" "iam-role" {
  name               = var.iam-role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance-profile" {
  name = "Jenkins-instance-profile"
  role = aws_iam_role.iam-role.name
}