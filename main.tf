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
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "aws-ue1a-dev-tfgt-pub01"
    Env  = "dev"
  }
}

# resource "aws_subnet" "PublicSubnet02" {
#   vpc_id            = aws_vpc.myvpc.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1b"

#   tags = {
#     Name = "aws-ue1b-dev-tfgt-pub02"
#     Env  = "dev"
#   }
# }


## Create Private Subnet

resource "aws_subnet" "PrivateSubnet01" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "aws-ue1a-dev-tfgt-pvt01"
    Env  = "dev"
  }
}

resource "aws_subnet" "PrivateSubnet02" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "aws-ue1b-dev-tfgt-pvt02"
    Env  = "dev"
  }
}

resource "aws_subnet" "PrivateSubnet03" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "aws-ue1a-dev-tfgt-pvt03"
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

# resource "aws_route_table_association" "PublicRTassociation2" {
#   subnet_id      = aws_subnet.PublicSubnet02.id
#   route_table_id = aws_route_table.PublicRT.id
# }


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

resource "aws_route_table_association" "PrivateRTassociation3" {
  subnet_id      = aws_subnet.PrivateSubnet03.id
  route_table_id = aws_route_table.PrivateRT.id
}


##### Application Load Balancer #####


## Create Security Group for ALB

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-webserver-sg"
    Env  = "dev"
  }
}


## Create Target Group

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 4
    unhealthy_threshold = 2
  }

  tags = {
    Name = "webserver-target-group"
    Env  = "dev"
  }
}


## Create ALB

resource "aws_lb" "app_alb" {
  name               = "webserver-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.PublicSubnet01.id, aws_subnet.PrivateSubnet02.id]

  tags = {
    Name = "app-alb"
    Env  = "dev"
  }
}


## Create Listener for ALB

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
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

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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


## Encode User Data

data "local_file" "user_data" {
  filename = "./user-data.sh"
}

## Create Launch Template

resource "aws_launch_template" "app_launch_template" {
  name_prefix            = "app-launch-template"
  image_id               = var.image_id
  instance_type          = var.size
  key_name               = var.key
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(data.local_file.user_data.content)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server"
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
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  vpc_zone_identifier = [
    aws_subnet.PrivateSubnet01.id,
    aws_subnet.PrivateSubnet02.id
  ]

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-server"
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

## Create Security Group for RDS

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "websaerver-rds_sg"
    Env  = "dev"
  }
}


## Create DB Subnet Group

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.PrivateSubnet01.id, aws_subnet.PrivateSubnet02.id, aws_subnet.PrivateSubnet03.id]

  tags = {
    Name = "webserver-rds_subnet_group"
    Env  = "dev"
  }
}


## Create RDS Instance

resource "aws_db_instance" "mysql_rds" {
  identifier           = var.db_identifier
  allocated_storage    = 20
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = var.db_parameter_group_name
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name = "webserver-mysql-rds"
    Env  = "dev"
  }
}


##### Bastion Ec2 #####

## Create SG for Bastion ec2

resource "aws_security_group" "bastion_ec2_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "bastion-ec2-sg"
    Env  = "dev"
  }
}


## Create bastion ec2

resource "aws_instance" "bastion_ec2" {
  ami                         = "ami-0069eac59d05ae12b"
  instance_type               = var.size
  key_name                    = var.key
  vpc_security_group_ids      = [aws_security_group.bastion_ec2_sg.id]
  subnet_id                   = aws_subnet.PublicSubnet01.id
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true

  tags = {
    Name = "Bastion-ec2"
    Env  = "dev"
  }
}
