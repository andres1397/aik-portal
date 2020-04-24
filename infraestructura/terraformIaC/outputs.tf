 
output "IP-PORTAL" {
  value = "${aws_instance.aik-portal-front.public_ip}"
}