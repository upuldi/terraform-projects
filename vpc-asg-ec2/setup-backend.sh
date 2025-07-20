#!/bin/bash
set -e

# S3 Backend Setup Script for Terraform Workspaces
# This script creates the necessary S3 bucket and DynamoDB table for Terraform state management

REGION=${1:-ap-southeast-2}
BUCKET_NAME=${2:-"terraform-state-$(whoami)-$(date +%s)"}
DYNAMODB_TABLE=${3:-"terraform-locks"}

echo "🚀 Setting up Terraform S3 Backend"
echo "=================================="
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ Error: AWS CLI not configured or no valid credentials"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured"

# Create S3 bucket
echo "🪣 Creating S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Bucket already exists: $BUCKET_NAME"
else
    if [ "$REGION" = "us-east-1" ]; then
        # us-east-1 doesn't need LocationConstraint
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "✅ Created S3 bucket: $BUCKET_NAME"
fi

# Enable versioning
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
echo "✅ Versioning enabled"

# Enable encryption
echo "🔐 Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
echo "✅ Encryption enabled"

# Block public access
echo "🛡️ Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo "✅ Public access blocked"

# Create DynamoDB table for locking
echo "🔒 Creating DynamoDB table: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" &>/dev/null; then
    echo "✅ DynamoDB table already exists: $DYNAMODB_TABLE"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region "$REGION"
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "✅ Created DynamoDB table: $DYNAMODB_TABLE"
fi

echo ""
echo "🎉 Backend setup complete!"
echo "=========================="
echo ""
echo "📋 Backend Configuration for versions.tf:"
echo ""
cat << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "vpc-asg-ec2/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo ""
echo "🔧 Next Steps:"
echo "1. Update your versions.tf with the above backend configuration"
echo "2. Run: terraform init"
echo "3. Start using workspaces: ./workspace-deploy.sh dev plan"
echo ""
echo "💾 State files will be stored as:"
echo "   - Default: s3://$BUCKET_NAME/vpc-asg-ec2/terraform.tfstate"
echo "   - Dev:     s3://$BUCKET_NAME/vpc-asg-ec2/env:/dev/terraform.tfstate"
echo "   - Staging: s3://$BUCKET_NAME/vpc-asg-ec2/env:/staging/terraform.tfstate"
echo "   - Prod:    s3://$BUCKET_NAME/vpc-asg-ec2/env:/prod/terraform.tfstate"
