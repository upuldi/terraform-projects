# 🏗️ Multi-Environment Workspace Guide

This project now supports **multiple environments** using **Terraform Workspaces**. Each environment is isolated with its own state file and configuration.

## 🌍 Available Environments

| Environment | Purpose | Instance Type | VPC CIDR | Scaling |
|-------------|---------|---------------|----------|---------|
| **dev** | Development & Testing | t2.micro | 10.10.0.0/16 | 1-2 instances |
| **staging** | Pre-production | t3.small | 10.20.0.0/16 | 2-4 instances |
| **prod** | Production | t3.medium | 10.30.0.0/16 | 3-6 instances |

## 🚀 Quick Start

### 1. **Initialize and Setup**
```bash
# Initialize Terraform
terraform init

# Check workspace status
./workspace-status.sh

# Create and switch to dev workspace
terraform workspace new dev
```

### 2. **Deploy to Development**
```bash
# Plan dev environment
./workspace-deploy.sh dev plan

# Apply dev environment
./workspace-deploy.sh dev apply
```

### 3. **Deploy to Staging**
```bash
# Switch to staging and deploy
./workspace-deploy.sh staging plan
./workspace-deploy.sh staging apply
```

### 4. **Deploy to Production**
```bash
# Switch to production and deploy
./workspace-deploy.sh prod plan
./workspace-deploy.sh prod apply
```

## 🔧 Manual Workspace Management

### **Workspace Commands**
```bash
# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new <environment>

# Switch workspace
terraform workspace select <environment>

# Show current workspace
terraform workspace show

# Delete workspace (after destroying resources)
terraform workspace delete <environment>
```

### **Environment-Specific Operations**
```bash
# Plan specific environment
terraform plan -var-file="terraform.tfvars.dev"

# Apply specific environment
terraform apply -var-file="terraform.tfvars.staging"

# Destroy specific environment
terraform destroy -var-file="terraform.tfvars.prod"
```

## 📊 Environment Configurations

### **Development (dev)**
- **Cost-optimized** for development work
- **Single NAT Gateway** to reduce costs
- **Minimal scaling** (1-2 instances)
- **Small instances** (t2.micro)

### **Staging (staging)**
- **Production-like** configuration
- **Medium scaling** (2-4 instances)
- **Better performance** instances (t3.small)

### **Production (prod)**
- **High availability** (multiple NAT Gateways)
- **Production scaling** (3-6 instances)
- **Production-grade** instances (t3.medium)

## 🔒 State Management

### **Workspace State Isolation**
Each workspace maintains its own state file:
```
S3 Bucket Structure:
├── vpc-asg-ec2/terraform.tfstate              # default workspace
├── vpc-asg-ec2/env:/dev/terraform.tfstate     # dev workspace
├── vpc-asg-ec2/env:/staging/terraform.tfstate # staging workspace
└── vpc-asg-ec2/env:/prod/terraform.tfstate    # prod workspace
```

### **Backend Configuration**
- **S3 Backend**: Centralized state storage
- **DynamoDB Locking**: Prevents concurrent modifications
- **Encryption**: State files are encrypted at rest

## 🛡️ Security Considerations

### **Network Isolation**
- **Separate VPC CIDRs** per environment
- **No cross-environment** communication by default
- **Environment-specific** security groups and NACLs

### **Access Control**
- **Workspace-based** resource isolation
- **Environment-specific** IAM policies (if implemented)
- **Separate state files** prevent accidental cross-environment changes

## 🔍 Monitoring and Outputs

### **Check Environment Status**
```bash
# Quick status check
./workspace-status.sh

# Show current environment outputs
terraform output

# Show specific output
terraform output vpc_id

# Show network security summary
terraform output network_security_summary
```

### **Resource Verification**
```bash
# List all resources in current workspace
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Refresh state from actual infrastructure
terraform refresh -var-file="terraform.tfvars.dev"
```

## 🚨 Troubleshooting

### **Common Issues**

**Wrong Workspace**
```bash
# Check current workspace
terraform workspace show

# Switch to correct workspace
terraform workspace select dev
```

**Missing Configuration**
```bash
# Ensure tfvars file exists
ls terraform.tfvars.*

# Use correct file for environment
terraform plan -var-file="terraform.tfvars.dev"
```

**State File Issues**
```bash
# Verify backend configuration
terraform init

# Force unlock if locked
terraform force-unlock <lock-id>
```

## 📋 Best Practices

### **Development Workflow**
1. **Always check** current workspace before operations
2. **Use helper scripts** for consistency
3. **Test in dev** before promoting to staging
4. **Plan before apply** in all environments

### **Environment Promotion**
```bash
# Typical workflow
./workspace-deploy.sh dev apply      # Deploy to dev
./workspace-deploy.sh staging plan   # Plan staging changes
./workspace-deploy.sh staging apply  # Deploy to staging
./workspace-deploy.sh prod plan      # Plan production changes
./workspace-deploy.sh prod apply     # Deploy to production
```

### **Safety Measures**
- **Never apply directly** to production without planning
- **Use version control** for all configuration changes
- **Test workspace switches** before important operations
- **Backup important workspaces** before major changes

---

**🎯 This workspace setup provides clean environment isolation while maintaining a single, maintainable codebase with your excellent modular architecture.**
