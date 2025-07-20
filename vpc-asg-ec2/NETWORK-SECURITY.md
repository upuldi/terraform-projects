# Network Security Configuration

This document explains the network security layers implemented in this Terraform project.

## 🛡️ Security Layers

### 1. **Security Groups** (Instance Level)
- **Stateful** - Return traffic is automatically allowed
- **Instance-level** firewall rules
- **Protocol-specific** controls

### 2. **Network ACLs** (Subnet Level) ⭐ **NEW**
- **Stateless** - Must explicitly allow both inbound and outbound
- **Subnet-level** firewall rules
- **Additional layer** of security

### 3. **Route Tables**
- Control traffic routing between subnets
- Separate route tables for public and private subnets

## 📋 Network ACL Rules

### Public Subnets NACL
```
Purpose: Standard public subnet behavior
Rules:  Allow ALL traffic (inbound/outbound)
```

### Private Subnets NACL ⚠️ **RESTRICTIVE**
```
INBOUND RULES:
✅ Rule 100-10X: Allow ALL from Public Subnets (10.0.1.0/24, 10.0.2.0/24)
✅ Rule 200-20X: Allow ALL from Private Subnets (10.0.101.0/24, 10.0.102.0/24)
✅ Rule 300: Allow TCP 1024-65535 from 0.0.0.0/0 (Ephemeral ports for return traffic)
✅ Rule 310: Allow TCP 443 from 0.0.0.0/0 (HTTPS return traffic)
✅ Rule 320: Allow TCP 80 from 0.0.0.0/0 (HTTP return traffic)
❌ DENY: All other traffic

OUTBOUND RULES:
✅ Rule 100-10X: Allow ALL to Public Subnets
✅ Rule 200-20X: Allow ALL to Private Subnets
✅ Rule 300: Allow TCP 443 to 0.0.0.0/0 (HTTPS for updates/SSM)
✅ Rule 310: Allow TCP 80 to 0.0.0.0/0 (HTTP for updates)
✅ Rule 320: Allow TCP 1024-65535 to 0.0.0.0/0 (Ephemeral return ports)
✅ Rule 330: Allow TCP 53 to 0.0.0.0/0 (DNS)
✅ Rule 340: Allow UDP 53 to 0.0.0.0/0 (DNS)
❌ DENY: All other traffic
```

## 🔒 Security Benefits

### **Defense in Depth**
1. **Internet Gateway** → Controls internet access
2. **Route Tables** → Controls traffic routing 
3. **Network ACLs** → Subnet-level filtering ⭐ **NEW**
4. **Security Groups** → Instance-level filtering
5. **Application** → App-level security

### **Private Subnet Isolation**
- **No Direct Internet Access**: Private subnets can't receive direct traffic from internet
- **Public Subnet Gateway**: All traffic to private subnets must come through public subnets
- **Internal Communication**: Private subnets can communicate with each other
- **Managed Updates**: Still allows outbound for updates via NAT Gateway

## 📊 Traffic Flow Examples

### ✅ **ALLOWED Traffic Patterns**
```
Internet → Public ALB → Public EC2 → Private ALB → Private EC2
Public Subnet EC2 → Private Subnet EC2
Private Subnet EC2 → Private Subnet EC2
Private Subnet EC2 → Internet (via NAT Gateway)
```

### ❌ **BLOCKED Traffic Patterns**
```
Internet → Private Subnet EC2 (Direct access blocked)
External IP → Private ALB (Must go through public subnet)
Unauthorized protocols to private subnets
```

## 🧪 Testing NACL Rules

### Test from Public Instance:
```bash
# Should work - allowed by NACL
curl http://private-alb-dns/api/status

# Test connectivity to private instance
telnet <private-ip> 80
```

### Test from Internet:
```bash
# Should fail - blocked by NACL
curl http://<private-instance-ip>
```

### Verify NACL Configuration:
```bash
# List Network ACLs
aws ec2 describe-network-acls --region ap-southeast-2

# Check specific NACL rules
aws ec2 describe-network-acls --network-acl-ids <nacl-id>
```

## 🔧 Troubleshooting

### Common Issues:
1. **Connection Timeouts**: Check NACL rules for ephemeral ports
2. **Package Updates Failing**: Verify outbound HTTPS/HTTP rules
3. **SSM Not Working**: Ensure outbound 443 allowed
4. **DNS Resolution**: Check UDP/TCP 53 rules

### Debug Commands:
```bash
# Check effective NACL rules
terraform output network_security_summary

# Validate NACL associations
aws ec2 describe-subnets --subnet-ids <subnet-id>
```

## 📈 Monitoring

### CloudWatch Metrics:
- Monitor VPC Flow Logs for denied traffic
- Set up alerts for unusual patterns
- Track NACL rule effectiveness

### Best Practices:
- **Test thoroughly** before applying to production
- **Monitor traffic patterns** after implementation
- **Keep rules minimal** - only allow what's needed
- **Document changes** and reasons

---

**⚠️ Important**: Network ACLs are stateless, so you must explicitly allow both directions of traffic. This configuration provides strong isolation while maintaining necessary functionality.
