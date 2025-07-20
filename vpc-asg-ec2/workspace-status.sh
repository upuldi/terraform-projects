#!/bin/bash

# Workspace Status and Management Script
# Shows current workspace status and provides quick commands

echo "🏗️  Terraform Workspace Status"
echo "==============================="

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run: terraform init"
    exit 1
fi

# Show current workspace
CURRENT_WORKSPACE=$(terraform workspace show)
echo "📂 Current workspace: $CURRENT_WORKSPACE"

# List all workspaces
echo ""
echo "📋 Available workspaces:"
terraform workspace list

# Show workspace-specific information
echo ""
echo "🔍 Workspace Details:"
case $CURRENT_WORKSPACE in
    dev)
        echo "   Environment: Development"
        echo "   Instance Type: t2.micro"
        echo "   VPC CIDR: 10.10.0.0/16"
        echo "   Config File: terraform.tfvars.dev"
        ;;
    staging)
        echo "   Environment: Staging"
        echo "   Instance Type: t3.small"
        echo "   VPC CIDR: 10.20.0.0/16"
        echo "   Config File: terraform.tfvars.staging"
        ;;
    prod)
        echo "   Environment: Production"
        echo "   Instance Type: t3.medium"
        echo "   VPC CIDR: 10.30.0.0/16"
        echo "   Config File: terraform.tfvars.prod"
        ;;
    default)
        echo "   ⚠️  Default workspace - not configured for environments"
        echo "   💡 Switch to an environment workspace: terraform workspace select dev"
        ;;
    *)
        echo "   ❓ Unknown workspace configuration"
        ;;
esac

# Show quick commands
echo ""
echo "🚀 Quick Commands:"
echo "   ./workspace-deploy.sh dev plan     - Plan dev environment"
echo "   ./workspace-deploy.sh staging apply - Deploy staging environment"
echo "   ./workspace-deploy.sh prod plan     - Plan production environment"
echo ""
echo "   terraform workspace select dev      - Switch to dev workspace"
echo "   terraform workspace select staging  - Switch to staging workspace"
echo "   terraform workspace select prod     - Switch to prod workspace"
echo ""
echo "   terraform output                    - Show current workspace outputs"
echo "   terraform state list                - List current workspace resources"

# Check for pending changes
echo ""
echo "📊 Environment Status Check:"
for env in dev staging prod; do
    if [ -f "terraform.tfvars.$env" ]; then
        echo "   ✅ $env configuration ready"
    else
        echo "   ❌ $env configuration missing"
    fi
done

# Show state file information
echo ""
echo "💾 State Information:"
echo "   Backend: $(grep -A 10 'backend "s3"' versions.tf | grep 'bucket' | awk '{print $3}' | tr -d '"' || echo 'local')"
echo "   State Key: vpc-asg-ec2/env:/$CURRENT_WORKSPACE/terraform.tfstate"
