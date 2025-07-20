#!/bin/bash

# Quick verification script to check Terraform workspace setup

echo "🔍 Terraform Workspace Verification"
echo "===================================="

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized"
    echo "💡 Run: terraform init"
    exit 1
fi

echo "✅ Terraform initialized"

# Check current workspace
CURRENT_WORKSPACE=$(terraform workspace show 2>/dev/null || echo "error")
if [ "$CURRENT_WORKSPACE" = "error" ]; then
    echo "❌ Cannot determine current workspace"
    exit 1
fi

echo "📂 Current workspace: $CURRENT_WORKSPACE"

# List all workspaces
echo ""
echo "📋 Available workspaces:"
terraform workspace list

# Check configuration files
echo ""
echo "📄 Configuration files:"
for env in dev staging prod; do
    if [ -f "terraform.tfvars.$env" ]; then
        echo "   ✅ terraform.tfvars.$env"
    else
        echo "   ❌ terraform.tfvars.$env (missing)"
    fi
done

# Check if backend is configured
echo ""
echo "💾 Backend configuration:"
if grep -q "backend" versions.tf && ! grep -q "#.*backend" versions.tf; then
    echo "   📡 Remote backend (S3) configured"
    # Check if backend is accessible
    if terraform init -backend=false &>/dev/null; then
        echo "   ✅ Backend accessible"
    else
        echo "   ⚠️  Backend may have issues"
    fi
else
    echo "   💻 Local backend (no remote state)"
fi

# Suggest next steps
echo ""
echo "🚀 Next Steps:"
echo "   1. Create workspace:     terraform workspace new dev"
echo "   2. Plan infrastructure:  ./workspace-deploy.sh dev plan"
echo "   3. Apply infrastructure: ./workspace-deploy.sh dev apply"
echo "   4. Check outputs:        terraform output"

echo ""
echo "✅ Verification complete!"
