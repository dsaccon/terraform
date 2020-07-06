# Sample terraform config to bring up an AWS spot instance with associated security group and VPC
# Different auth key config options shown

#
variable "aws_secret_key" { default = "my-access-key" }
variable "aws_access_key" { default = "my-secret-key" }

#
variable "ami" { default = "ami-0bbe6b35405ecebdb" } # Ubuntu 18.04 image
variable "inst_type" { default = "t3a.medium" }
variable "region" { default = "us-west-2" }
variable "key_name" { default = "my_key" }
variable "spot_req_name" { default = "terraform_spot_test" }
variable "vol_size" { default = 100 }

# Using shared credentials file (default profile)
provider "aws" {
  alias             = "aws_def"
  profile           = "default"
  region            = var.region
}

# Using shared credentials file (non-default profile)
provider "aws" {
  alias             = "aws_2"
  profile           = "my_prof"
  region            = var.region
}

# Using static credentials
provider "aws" {
  alias             = "aws_static"
  region            = var.region
  access_key        = "my-access-key"
  secret_key        = "my-secret-key"
}

# Using static credentials (from variable)
provider "aws" {
  alias             = "aws_var"
  region            = var.region
  access_key        = var.aws_access_key
  secret_key        = var.aws_secret_key
}

resource "aws_default_vpc" "default" {
  provider          = aws.aws_2
  tags = {
    Name            = "Default VPC"
  }
}

resource "aws_default_security_group" "default" {
  provider          = aws.aws_2
  vpc_id            = aws_default_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_spot_instance_request" "spot_inst" {
  provider          = aws.aws_2
  ami               = var.ami
  instance_type     = var.inst_type
  key_name          = var.key_name
#  user_data         = file("${path.module}/init.sh")

  security_groups   = [
    aws_default_security_group.default.name
  ]

  tags = {
    Name            = var.spot_req_name
  }

  root_block_device {
    volume_size     = var.vol_size
    volume_type     = "gp2"
  }

}

output "ip_address" {
  value = "${aws_spot_instance_request.spot_inst.public_dns}"
}

output "instance_id" {
  value = "${aws_spot_instance_request.spot_inst.spot_instance_id}"
}
