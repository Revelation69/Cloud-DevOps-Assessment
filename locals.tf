locals {


  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["none"]
    },
    {
      rolearn  = module.eks_developer_iam_role.iam_role_arn
      username = module.eks_developer_iam_role.iam_role_name
      groups   = ["none"]
    }
  ]

  repository_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowECRAccess",
        Effect = "Allow",
        Principal = {
          "AWS" : module.eks_admins_iam_role.iam_role_arn
        },
        Action = [
          "ecr:ReplicateImage",
          "ecr:DescribeImageScanFindings",
          "ecr:StartImageScan",
          "ecr:GetDownloadUrlForLayer",
          "ecr:UploadLayerPart",
          "ecr:BatchDeleteImage",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DescribeRegistry",
          "ecr:DescribePullThroughCacheRules",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  })


  iam_role_additional_policies = {
    FullECRAccessPolicy = aws_iam_policy.ecr_access_for_worker_node.arn

  }

}
    