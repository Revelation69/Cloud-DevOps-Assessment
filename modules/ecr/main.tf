data "aws_caller_identity" "current" {}

module "ecr_frontend" {
  source                   = "terraform-aws-modules/ecr/aws"
  version                  = "1.5.1"
  repository_name          = var.frontend_repository_name
  repository_type          = var.frontend_repository_type
  create_lifecycle_policy  = var.frontend_create_lifecycle_policy
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  tags                              = var.tags
}

module "ecr_backend" {
  source                   = "terraform-aws-modules/ecr/aws"
  version                  = "1.5.1"
  repository_name          = var.backend_repository_name
  repository_type          = var.backend_repository_type
  create_lifecycle_policy  = var.backend_create_lifecycle_policy
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  tags                              = var.tags
}