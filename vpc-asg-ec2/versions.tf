terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "vpc-asg-ec2/terraform.tfstate"
  #   region = "us-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt = true
  # }
}