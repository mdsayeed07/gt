##### Create Infrastructure #####

## Create VPC

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "aws-ue1-dev-tfgt-vpc01"
    Env  = "dev"
  }
}


## Create Public Subnets

resource "aws_subnet" "PublicSubnet01" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "aws-ue1a-dev-tfgt-pub01"
    Env  = "dev"
  }
}

resource "aws_subnet" "PublicSubnet02" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "aws-ue1b-dev-tfgt-pub02"
    Env  = "dev"
  }
}


## Create Private Subnet

resource "aws_subnet" "PrivateSubnet01" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.10.0/24"

  tags = {
    Name = "aws-ue1a-dev-tfgt-pvt01"
    Env  = "dev"
  }
}

resource "aws_subnet" "PrivateSubnet02" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.11.0/24"

  tags = {
    Name = "aws-ue1b-dev-tfgt-pvt02"
    Env  = "dev"
  }
}


## Create Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "aws-ue1-dev-tfgt-igw01"
    Env  = "dev"
  }
}


## Create Route Table for public subnet

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "aws-ue1-dev-tfgt-rt01"
    Env  = "dev"
  }
}


## RT Association for public subnets

resource "aws_route_table_association" "PublicRTassociation1" {
  subnet_id      = aws_subnet.PublicSubnet01.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "PublicRTassociation2" {
  subnet_id      = aws_subnet.PublicSubnet02.id
  route_table_id = aws_route_table.PublicRT.id
}


## Create Elastic IP for NAT Gateway

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}


## Create NAT Gateway in public subnet 01

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.PublicSubnet01.id

  tags = {
    Name = "aws-ue1-dev-tfgt-NATgw"
    Env  = "dev"
  }
}


## Create Route Table for private subnets

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "aws-ue1-dev-tfgt-rt02"
    Env  = "dev"
  }
}


## RT Association for private subnets using for_each

resource "aws_route_table_association" "PrivateRTassociation1" {
  subnet_id      = aws_subnet.PrivateSubnet01.id
  route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_route_table_association" "PrivateRTassociation2" {
  subnet_id      = aws_subnet.PrivateSubnet02.id
  route_table_id = aws_route_table.PrivateRT.id
}


##### Auto Scaling Group #####


## Security Group for EC2 Instances

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_webserver_sg"
    Env  = "dev"
  }
}


## Create Launch Template

resource "aws_launch_template" "app_launch_template" {
  name_prefix            = "app-launch-template"
  image_id               = var.image_id
  instance_type          = var.size
  key_name               = var.key
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-instance"
      Env  = "dev"
    }
  }

  tags = {
    Name = "Webserver-launch-template"
    Env  = "dev"
  }
}


## Create Auto Scaling Group

resource "aws_autoscaling_group" "app_asg" {
  name                      = "app_asg"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.PrivateSubnet01.id,
    aws_subnet.PrivateSubnet02.id
  ]

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = "dev"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


##### Create RDS #####

## Create RDS


