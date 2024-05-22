terraform {
  backend "s3" {
    bucket         = "cloud-devops-assessment-s3"
    key            = "cloud-devops-assessment/terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-devops-assessment"
  }
}
