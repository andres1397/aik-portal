
variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "aik-ami-id" {
  default = "ami-0d6621c01e8c2de2c"
}

variable "vpc-name" {
  default = "aik-vpc-automatizacion-AguirreCoralUrbano"
}

variable "public-route-table-name" {
  default = "public-routetable-automatizacion-AguirreCoralUrbano"
}

variable "public-subnet-name" {
  default = "public-subnet1-automatizacion-AguirreCoralUrbano"
}

variable "aik-instance-type" {
  default = "t2.micro"
}

variable "aik-key-name" {
  default = "devops-automatizacion-AguirreCoralUrbano"
}

variable "aws-availability-zones" {
  default = "us-west-2a,us-west-2b"
}

variable "aik-instance-front-name" {
  default = "Aik front -automatizacion- AguirreCoralUrbano"
}

variable "aik-instance-back-name" {
  default = "Aik back -automatizacion- AguirreCoralUrbano"
}

variable "alb_name" {
  type = string
  default = "lb-automatizacion-AguirreCoralUrbano"
}

variable "alb_security_group_name" {
  type = string
  default = "sg-alb-automatizacion-AguirreCoralUrbano"
}

variable "public_subnet_cidr_blocks" {
  default     = ["10.0.0.0/16"]
  type        = list(string)
}
