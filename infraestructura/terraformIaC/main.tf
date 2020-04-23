provider "aws" {
  region = "us-east-1"
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

  name        = "portal-front"
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
    from_port   = "3000"
    to_port     = "3000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic trough port 3000 from backend"
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

  name        = "portal-back"
  description = "Security group for allow or deny traffic to Backend"
  vpc_id      = "${aws_vpc.aik-vpc.id}"

  ingress {
    from_port   = "3000"
    to_port     = "3000"
    protocol    = "tcp"
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

/*
resource "aws_autoscaling_group" "autoscaling-front"{

    launch_configuration = "${aws_launch_configuration.example_launch.name}"
    min_size = 1
    max_size = 2
    desired_capacity = 1
    vpc_zone_identifier = ["${data.aws_subnet_ids.default_subnet.ids}"]

    tag = {
        key = "Name"
        value = "example-ags"
        propagate_at_launch = true

    }

}

resource "aws_launch_configuration" "launch-front" {
  image_id = "${var.aik-ami-id}"
  instance_type = "${var.aik-instance-type}"
  security_groups = ["${aws_security_group.aik-sg-portal-front}"]
  
  
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