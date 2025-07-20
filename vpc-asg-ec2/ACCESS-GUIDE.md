# Infrastructure Access Guide

## SSM Session Manager Access

This infrastructure uses AWS Systems Manager Session Manager for secure access to EC2 instances. No SSH keys are required.

### Access Pattern

```
User → SSM → Public Instance → SSM → Private Instance
```

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Session Manager plugin** installed:
   ```bash
   # Install Session Manager plugin
   curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
   unzip sessionmanager-bundle.zip
   sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
   ```

### Access Instructions

#### 1. Access Public Instances (Direct)
```bash
# List running instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=*public*" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table

# Connect to public instance
aws ssm start-session --target i-1234567890abcdef0
```

#### 2. Access Private Instances (Via Public Instance)
```bash
# Step 1: Connect to public instance
aws ssm start-session --target <public-instance-id>

# Step 2: From public instance, connect to private instance
aws ssm start-session --target <private-instance-id>
```

### Getting Instance IDs

Use Terraform outputs to get instance information:
```bash
# Get all infrastructure details
terraform output

# Or use AWS CLI
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' --output table
```

### Security Features

- **No SSH keys required** - Uses IAM-based access control
- **Layered access** - Private instances only accessible via public instances
- **Full audit trail** - All sessions logged in CloudTrail
- **Network isolation** - Private instances cannot be accessed directly

### Web Application Access

- **Public Application**: `http://<public-alb-dns-name>`
- **Internal API**: Accessible from public instances to private ALB

### Troubleshooting

1. **Session Manager not working**: Ensure IAM permissions and SSM agent is running
2. **Cannot reach private instances**: Verify you're connecting through public instance
3. **Application not loading**: Check security groups and target group health

For more details, see the Terraform outputs: `terraform output`
