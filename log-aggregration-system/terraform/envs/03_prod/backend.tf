terraform {
  backend "s3" {
    bucket         = "prod"
    key            = "helm/log-aggregation-system.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
