provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "aik-vpc" {

  cidr_block = var.vpc-cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.vpc-name
  }
}

# Creación del Internet Gateway
resource "aws_internet_gateway" "aik-igw" {
  vpc_id = aws_vpc.aik-vpc.id
}

# Creación de una tabla de ruteo pública
resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.aik-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aik-igw.id
  }

  tags = {
    Name = var.public-route-table-name
  }

}

resource "aws_subnet" "another-subnet-public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id = aws_vpc.aik-vpc.id
  cidr_block = cidrsubnet(var.public_subnet_cidr_blocks[count.index], 8, 3)
  availability_zone = element(split(",", var.aws-availability-zones), count.index+1)
  map_public_ip_on_launch = true
  tags = {
    Name = "Public2-another-subnet-AguirreCoralUrbano"
  }
}

# Creación y asociación de la subred publica con la tabla de ruteo
resource "aws_subnet" "aik-subnet-public" {
/*
  vpc_id                  = aws_vpc.aik-vpc.id
  cidr_block              = cidrsubnet(var.vpc-cidr, 8, 1)
  availability_zone       = element(split(",", var.aws-availability-zones), count.index)
  map_public_ip_on_launch = true
  */

  count = length(var.public_subnet_cidr_blocks)
  vpc_id = aws_vpc.aik-vpc.id
  cidr_block = cidrsubnet(var.public_subnet_cidr_blocks[count.index], 8, 1)
  availability_zone = element(split(",", var.aws-availability-zones), count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = var.public-subnet-name
  }
}

# Asociación entre la tabla de ruteo y la subred publica
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.aik-subnet-public[count.index].id
  route_table_id = aws_route_table.rtb-public.id

}

resource "aws_route_table_association" "public2" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.aik-subnet-public[count.index].id
  route_table_id = aws_route_table.rtb-public.id
}

# Creación del grupo de seguridad para el front
resource "aws_security_group" "aik-sg-portal-front"{

  name        = "portal-front-automatizacion"
  description = "Security group for allow traffic to Frontend"
  vpc_id      = aws_vpc.aik-vpc.id

  ingress {
    from_port   = "3030"
    to_port     = "3030"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic trough port 3030 from anywhere"
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH allowed from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creación del grupo de seguridad para el back
resource "aws_security_group" "aik-sg-portal-back" {

  name        = "portal-back-automatizacion"
  description = "Security group for allow or deny traffic to Backend"
  vpc_id      = aws_vpc.aik-vpc.id

  ingress {
    from_port   = "3000"
    to_port     = "3000"
    protocol    = "tcp"
    security_groups = [aws_security_group.aik-sg-portal-front.id]
  }

    ingress {
    from_port = "8"
    to_port = "0"
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db-sg" {
  name = "db-sg"
  vpc_id = aws_vpc.aik-vpc.id

  ingress {
    from_port = "3306"
    protocol = "tcp"
    to_port = "3306"
    security_groups = [aws_security_group.aik-sg-portal-back.id]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_autoscaling_group" "autoscaling-front"{
    count = length(var.public_subnet_cidr_blocks)

    launch_configuration = aws_launch_configuration.launch-front[count.index].name
    min_size = 1
    max_size = 2
    desired_capacity = 1
    vpc_zone_identifier = [aws_subnet.aik-subnet-public[count.index].id]
    target_group_arns = [aws_lb_target_group.lb-target-front.arn]

    tag {
        key = "Name"
        value = var.aik-instance-front-name
        propagate_at_launch = true
    }

}

resource "aws_launch_configuration" "launch-front" {
  count = length(var.public_subnet_cidr_blocks)
  image_id = var.aik-ami-id
  instance_type = var.aik-instance-type
  security_groups = [aws_security_group.aik-sg-portal-front.id]
  key_name = var.aik-key-name

  depends_on = [aws_instance.aik-portal-back]

  user_data = <<-EOF
      #!/bin/bash
      sudo yum update -y
      sudo yum install -y git
      # Clonar nuestro repositorio
      sudo git clone -b Feature-FrontBackInfra-ImplementacionDiseñoAWS https://github.com/andres1397/aik-portal /srv/aik-portal

      # Crear variable de entorno

      echo "BACKIP="${aws_instance.aik-portal-back[count.index].private_ip}"" >> /etc/environment

      # Instalar SaltStack
      #sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
      sudo curl -L https://bootstrap.saltstack.com -o bootstrap_salt.sh
      sudo sh bootstrap_salt.sh
      #sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off

      #Put custom minion config in place (for enabling masterless mode)
      sudo cp -r /srv/aik-portal/Configuration_Managment/minion.d /etc/salt/
      echo -e 'grains:\n roles:\n  - frontend' | sudo tee /etc/salt/minion.d/grains.conf

      # Realizar un saltstack completo
      sudo salt-call state.apply

      EOF

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_lb" "load-balancer" {
    count = length(var.public_subnet_cidr_blocks)

    name = var.alb_name
    load_balancer_type = "application"
    subnets = [aws_subnet.aik-subnet-public[count.index].id, aws_subnet.another-subnet-public[count.index].id]
    security_groups = [
      aws_security_group.sg_lb.id]
}

resource "aws_lb_target_group" "lb-target-front" {

  name = var.alb_name
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.aik-vpc.id

  health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
  }
}

resource "aws_security_group" "sg_lb" {
    name = var.alb_security_group_name
    vpc_id = aws_vpc.aik-vpc.id

    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_listener" "http" {
  count = length(var.public_subnet_cidr_blocks)
  load_balancer_arn = aws_lb.load-balancer[count.index].arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  count = length(var.public_subnet_cidr_blocks)
  listener_arn = aws_lb_listener.http[count.index].arn
  priority = 100

  condition {
    path_pattern{
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb-target-front.arn
  }

}


resource "aws_instance" "aik-portal-back" {
  count = length(var.public_subnet_cidr_blocks)

  ami                    = var.aik-ami-id
  instance_type          = var.aik-instance-type
  key_name               = var.aik-key-name
  vpc_security_group_ids = [aws_security_group.aik-sg-portal-back.id]
  subnet_id              = aws_subnet.aik-subnet-public[count.index].id
  tags = { Name = var.aik-instance-back-name }

  user_data = file("./scripts/back.sh")

}

/*resource "aws_instance" "aik-portal-front" {
  count = length(var.public_subnet_cidr_blocks)

  ami                    = var.aik-ami-id
  instance_type          = var.aik-instance-type
  key_name               = var.aik-key-name
  vpc_security_group_ids = [aws_security_group.aik-sg-portal-front.id]
  subnet_id              = aws_subnet.aik-subnet-public[count.index].id
  tags = { Name = var.aik-instance-front-name }

  depends_on = [aws_instance.aik-portal-back]

  user_data = file("./scripts/front.sh")

}*/

resource "aws_db_subnet_group" "subnet-db-group" {
  count = length(var.public_subnet_cidr_blocks)
  name = "subnet-db-aguirre-coral-urbano"
  subnet_ids = [aws_subnet.aik-subnet-public[count.index].id, aws_subnet.another-subnet-public[count.index].id]
}

resource "aws_db_instance" "My-SQL-Database" {
  count = length(var.public_subnet_cidr_blocks)

  identifier = "db-rds-aguirre-coral-urbano"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  instance_class = "db.t2.micro"
  engine_version = "5.7"
  name = "dbRDSAguirreCoralUrbano"
  username = "myrds"
  password = "mysqlrds"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.subnet-db-group[count.index].id
}