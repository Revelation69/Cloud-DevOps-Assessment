terraform {
  backend "s3" {
    bucket         = "cloud-devops-assessment-s3-bucket"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-devops-assessment"
  }
}