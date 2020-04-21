variable "aik-ami-id" {
  default = "ami-0fc61db8544a617ed"
}

variable "vpc-name" {
  default = "aik-vpc-AguirreCoralUrbano"
}

variable "public-route-table-name" {
  default = "public-routetable-AguirreCoralUrbano"
}

variable "public-subnet-name" {
  default = "public-subnet1-AguirreCoralUrbano"
}

variable "aik-instance-type" {
  default = "t2.micro"
}

variable "aik-key-name" {
  default = "devops"
}

variable "aws-availability-zones" {
  default = "us-east-1a,us-east-1b"
}

variable "aik-instance-front-name" {
  default = "Aik front - AguirreCoralUrbano"
}

variable "aik-instance-back-name" {
  default = "Aik back - AguirreCoralUrbano"
}
