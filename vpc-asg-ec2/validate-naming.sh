#!/bin/bash

# Resource Naming Validation Script
# Checks if Terraform resource names will exceed AWS limits

echo "🔍 Terraform Resource Naming Validation"
echo "========================================"

# Check if we're in a terraform directory
if [ ! -f "terraform.tfvars.dev" ]; then
    echo "❌ No terraform.tfvars.dev found. Run from terraform project directory."
    exit 1
fi

# Function to validate naming for each environment
validate_environment() {
    local env=$1
    local tfvars_file="terraform.tfvars.$env"
    
    if [ ! -f "$tfvars_file" ]; then
        echo "⚠️  Skipping $env - $tfvars_file not found"
        return
    fi
    
    echo ""
    echo "📋 Validating $env environment..."
    
    # Extract values from tfvars file
    local name=$(grep '^name' "$tfvars_file" | cut -d'"' -f2)
    local environment=$(grep '^environment' "$tfvars_file" | cut -d'"' -f2)
    
    if [ -z "$name" ] || [ -z "$environment" ]; then
        echo "❌ Could not extract name or environment from $tfvars_file"
        return
    fi
    
    local name_prefix="${name}-${environment}"
    
    echo "   Name: $name"
    echo "   Environment: $environment"
    echo "   Name Prefix: $name_prefix (${#name_prefix} chars)"
    
    # ALB naming checks
    local alb_public="${name_prefix}-public-alb"
    local alb_private="${name_prefix}-private-alb"
    local tg_public="${alb_public}-tg"
    local tg_private="${alb_private}-tg"
    
    echo ""
    echo "   🏗️  ALB Resources:"
    
    # Check ALB names (32 char limit)
    if [ ${#alb_public} -le 32 ]; then
        echo "   ✅ Public ALB: $alb_public (${#alb_public} chars)"
    else
        echo "   ❌ Public ALB: $alb_public (${#alb_public} chars) - EXCEEDS 32 LIMIT!"
    fi
    
    if [ ${#alb_private} -le 32 ]; then
        echo "   ✅ Private ALB: $alb_private (${#alb_private} chars)"
    else
        echo "   ❌ Private ALB: $alb_private (${#alb_private} chars) - EXCEEDS 32 LIMIT!"
    fi
    
    # Check Target Group names (32 char limit)
    if [ ${#tg_public} -le 32 ]; then
        echo "   ✅ Public TG: $tg_public (${#tg_public} chars)"
    else
        echo "   ❌ Public TG: $tg_public (${#tg_public} chars) - EXCEEDS 32 LIMIT!"
    fi
    
    if [ ${#tg_private} -le 32 ]; then
        echo "   ✅ Private TG: $tg_private (${#tg_private} chars)"
    else
        echo "   ❌ Private TG: $tg_private (${#tg_private} chars) - EXCEEDS 32 LIMIT!"
    fi
    
    # Security Group names (255 char limit - usually not an issue)
    local sg_public="${name_prefix}-alb-public-sg"
    local sg_private="${name_prefix}-alb-private-sg"
    
    echo ""
    echo "   🛡️  Security Groups:"
    echo "   ✅ Public SG: $sg_public (${#sg_public} chars)"
    echo "   ✅ Private SG: $sg_private (${#sg_private} chars)"
}

# Validate all environments
validate_environment "dev"
validate_environment "staging"
validate_environment "prod"

echo ""
echo "📊 AWS Resource Name Limits:"
echo "   - ALB/Target Groups: 32 characters"
echo "   - Security Groups: 255 characters"
echo "   - Launch Templates: 128 characters"
echo "   - Auto Scaling Groups: 255 characters"

echo ""
echo "💡 Naming Best Practices:"
echo "   - Keep base name short (e.g., 'myapp' not 'myapp-staging')"
echo "   - Let environment suffix handle differentiation"
echo "   - Use abbreviations if needed (e.g., 'stg' instead of 'staging')"

echo ""
echo "✅ Validation complete!"
