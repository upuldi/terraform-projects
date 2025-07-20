terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for multi-environment workspaces
  # Comment out the backend block if you don't have S3 bucket setup yet
  # Uncomment and configure when ready for remote state
  
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"  # Replace with your actual bucket name
  #   key            = "vpc-asg-ec2/terraform.tfstate"
  #   region         = "us-east-1"                    # Must match your bucket's region
  #   dynamodb_table = "terraform-locks"              # Replace with your DynamoDB table
  #   encrypt        = true
  #   
  #   # Workspace-aware state files:
  #   # Default workspace: vpc-asg-ec2/terraform.tfstate  
  #   # dev workspace:     vpc-asg-ec2/env:/dev/terraform.tfstate
  #   # staging workspace: vpc-asg-ec2/env:/staging/terraform.tfstate
  #   # prod workspace:    vpc-asg-ec2/env:/prod/terraform.tfstate
  # }
}