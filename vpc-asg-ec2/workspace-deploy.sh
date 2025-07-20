#!/bin/bash
set -e

# Terraform Workspace Management Script
# Usage: ./workspace-deploy.sh <environment> [plan|apply|destroy]

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment must be one of: dev, staging, prod"
    echo "Usage: $0 <environment> [plan|apply|destroy]"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|init)$ ]]; then
    echo "❌ Error: Action must be one of: init, plan, apply, destroy"
    echo "Usage: $0 <environment> [plan|apply|destroy]"
    exit 1
fi

echo "🚀 Managing Terraform for environment: $ENVIRONMENT"
echo "📋 Action: $ACTION"
echo "----------------------------------------"

# Initialize if needed
if [ ! -d ".terraform" ] || [ "$ACTION" = "init" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Create workspace if it doesn't exist
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "🏗️  Creating workspace: $ENVIRONMENT"
    terraform workspace new "$ENVIRONMENT"
else
    echo "📂 Selecting workspace: $ENVIRONMENT"
    terraform workspace select "$ENVIRONMENT"
fi

# Get current workspace to confirm
CURRENT_WORKSPACE=$(terraform workspace show)
echo "✅ Current workspace: $CURRENT_WORKSPACE"

# Set the appropriate tfvars file
TFVARS_FILE="terraform.tfvars.$ENVIRONMENT"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Error: Configuration file $TFVARS_FILE not found!"
    exit 1
fi

echo "📄 Using configuration: $TFVARS_FILE"

# Execute the requested action
case $ACTION in
    plan)
        echo "📋 Planning infrastructure for $ENVIRONMENT..."
        terraform plan -var-file="$TFVARS_FILE" -out="$ENVIRONMENT.tfplan"
        echo "✅ Plan saved to: $ENVIRONMENT.tfplan"
        ;;
    apply)
        echo "🚀 Applying infrastructure for $ENVIRONMENT..."
        if [ -f "$ENVIRONMENT.tfplan" ]; then
            terraform apply "$ENVIRONMENT.tfplan"
            rm "$ENVIRONMENT.tfplan"
        else
            terraform apply -var-file="$TFVARS_FILE" -auto-approve
        fi
        echo "✅ Infrastructure deployed to $ENVIRONMENT"
        ;;
    destroy)
        echo "💥 Destroying infrastructure for $ENVIRONMENT..."
        echo "⚠️  This will destroy ALL resources in the $ENVIRONMENT environment!"
        read -p "Are you sure? Type 'yes' to continue: " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy -var-file="$TFVARS_FILE" -auto-approve
            echo "✅ Infrastructure destroyed in $ENVIRONMENT"
        else
            echo "❌ Destroy cancelled"
        fi
        ;;
esac

echo "----------------------------------------"
echo "🎉 Operation completed successfully!"
echo "📊 To see outputs: terraform output"
echo "🔍 Current workspace: $(terraform workspace show)"
