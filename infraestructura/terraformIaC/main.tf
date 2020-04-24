provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "aik-vpc" {

  cidr_block = "${var.vpc-cidr}"

  tags {
    Name = "${var.vpc-name}"
  }
}

# Creación del Internet Gateway
resource "aws_internet_gateway" "aik-igw" {
  vpc_id = "${aws_vpc.aik-vpc.id}"
}

# Creación de una tabla de ruteo pública
resource "aws_route_table" "rtb-public" {
  vpc_id = "${aws_vpc.aik-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aik-igw.id}"
  }

  tags {
    Name = "${var.public-route-table-name}"
  }

}

# Creación y asociación de la subred publica con la tabla de ruteo
resource "aws_subnet" "aik-subnet-public" {

  vpc_id                  = "${aws_vpc.aik-vpc.id}"
  cidr_block              = "${cidrsubnet(var.vpc-cidr, 8, 1)}"
  availability_zone       = "${element(split(",", var.aws-availability-zones), count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.public-subnet-name}"
  }
}

# Asociación entre la tabla de ruteo y la subred publica
resource "aws_route_table_association" "public" {

  subnet_id      = "${aws_subnet.aik-subnet-public.id}"
  route_table_id = "${aws_route_table.rtb-public.id}"

}

# Creación del grupo de seguridad para el front
resource "aws_security_group" "aik-sg-portal-front"{

  name        = "portal-front-automatizacion-AguirreCoralUrbano"
  description = "Security group for allow traffic to Frontend"
  vpc_id      = "${aws_vpc.aik-vpc.id}"

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

  name        = "portal-back-automatizacion-AguirreCoralUrbano"
  description = "Security group for allow or deny traffic to Backend"
  vpc_id      = "${aws_vpc.aik-vpc.id}"

  ingress {
    from_port   = "3000"
    to_port     = "3000"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.aik-sg-portal-front.id}"]
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

/*
resource "aws_autoscaling_group" "autoscaling-front"{

    launch_configuration = "${aws_launch_configuration.launch-front.name}"
    min_size = 1
    max_size = 2
    desired_capacity = 1
    vpc_zone_identifier = ["${aws_subnet.aik-subnet-public.id}"]
    target_group_arns = ["${aws_lb_target_group.lb-target-front.arn}"]

    tag = {
        key = "Name"
        value = "example-ags"
        propagate_at_launch = true

    }

}

resource "aws_launch_configuration" "launch-front" {
  image_id = "${var.aik-ami-id}"
  instance_type = "${var.aik-instance-type}"
  security_groups = ["${aws_security_group.aik-sg-portal-front.id}"]
  
  
  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git 
        # Clonar nuestro repositorio 
        git clone https://github.com/andres1397/aik-portal /srv/aik-portal

        # Instalar SaltStack
        sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
        sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
        
        #Put custom minion config in place (for enabling masterless mode)
        sudo cp -r /srv/aik-portal/Configuration_management/minion.d /etc/salt/
        echo -e 'grains:\n roles:\n  - frontend' > /etc/salt/minion.d/grains.conf
        
        # Realizar un saltstack completo
        sudo salt-call state.apply
        EOF
   lifecycle = {
      create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling-back"{

    launch_configuration = "${aws_launch_configuration.launch-back.name}"
    min_size = 1
    max_size = 2
    desired_capacity = 1
    vpc_zone_identifier = ["${aws_subnet.aik-subnet-public.id}"]
    target_group_arns = ["${aws_lb_target_group.lb-target-back.arn}"]

    tag = {
        key = "Name"
        value = "example-ags"
        propagate_at_launch = true
    }

}

resource "aws_launch_configuration" "launch-back" {
  image_id = "${var.aik-ami-id}"
  instance_type = "${var.aik-instance-type}"
  security_groups = ["${aws_security_group.aik-sg-portal-back.id}"]
  
  
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git 
        # Clonar nuestro repositorio 
        git clone https://github.com/andres1397/aik-portal /srv/aik-portal
        
        # Instalar SaltStack
        sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
        sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
        
        #Put custom minion config in place (for enabling masterless mode)
        sudo cp -r /srv/aik-portal/Configuration_management/minion.d /etc/salt/
        echo -e 'grains:\n roles:\n  - backend' > /etc/salt/minion.d/grains.conf
        
        # Realizar un saltstack completo
        sudo salt-call state.apply
        EOF
   lifecycle = {
      create_before_destroy = true
  }
}

resource "aws_lb" "load-balancer" {
    name = "${var.alb_name}"
    load_balancer_type = "application"
    subnets = ["${data.aws_subnet_ids.default_subnet.ids}"]
    security_groups = ["${aws_security_group.sg_lb.id}"]
}

resource "aws_lb_target_group" "lb-target-back" {
  
  name = "${var.alb_name}"
  port = "${var.server_port}"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.aik-vpc.id}"

  health_check = {
      path = "/"
      protocol = "HTTP"
      mather = "200"
      interval = 15
      timeout = 3
      health_threshould = 2
      unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "lb-target-front" {
  
  name = "${var.alb_name}"
  port = "${var.server_port}"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.aik-vpc.id}"

  health_check = {
      path = "/"
      protocol = "HTTP"
      mather = "200"
      interval = 15
      timeout = 3
      health_threshould = 2
      unhealthy_threshold = 2
  }
}

resource "aws_security_group" "sg_lb" {
    name = "${var.alb_security_group_name}"

    ingress{
        from_port = 80
        to_port = 80
        protocol = "HTTP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



*/

resource "aws_instance" "aik-portal-front" {

  ami                    = "${var.aik-ami-id}"
  instance_type          = "${var.aik-instance-type}"
  key_name               = "${var.aik-key-name}"
  vpc_security_group_ids = ["${aws_security_group.aik-sg-portal-front.id}"]
  subnet_id              = "${aws_subnet.aik-subnet-public.id}"
  tags { Name = "${var.aik-instance-front-name}" }

  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git 
        # Clonar nuestro repositorio 
        sudo git clone -b Feature-FrontBackInfra-ImplementacionDiseñoAWS https://github.com/andres1397/aik-portal /srv/aik-portal

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

}

resource "aws_instance" "aik-portal-back" {

  ami                    = "${var.aik-ami-id}"
  instance_type          = "${var.aik-instance-type}"
  key_name               = "${var.aik-key-name}"
  vpc_security_group_ids = ["${aws_security_group.aik-sg-portal-back.id}"]
  subnet_id              = "${aws_subnet.aik-subnet-public.id}"
  tags { Name = "${var.aik-instance-back-name}" }

  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git 
        # Clonar nuestro repositorio 
        git clone https://github.com/andres1397/aik-portal /srv/aik-portal
        
        # Instalar SaltStack
        sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
        sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
        
        #Put custom minion config in place (for enabling masterless mode)
        sudo cp -r /srv/aik-portal/Configuration_management/minion.d /etc/salt/
        echo -e 'grains:\n roles:\n  - backend' > /etc/salt/minion.d/grains.conf
        
        # Realizar un saltstack completo
        sudo salt-call state.apply
        EOF

}