# Use the latest Amazon Linux 2 AMI for ap-southeast-2 region.
# To update the AMI selection, modify the filters in the data source below.
# The following AMI filter is specific to the ap-southeast-2 region.
# If you change the AWS region, update the filter values accordingly.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
