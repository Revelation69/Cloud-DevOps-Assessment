locals {


  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups = ["none"]
    },
    {
      rolearn  = module.eks_developer_iam_role.iam_role_arn
      username = module.eks_developer_iam_role.iam_role_name
      groups = ["none"]
    }
  ]


}

    