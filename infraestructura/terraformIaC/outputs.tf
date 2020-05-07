 
output "IP-PORTAL" {
  value = aws_instance.aik-portal-front[0].public_ip
}

output "DB" {
  value = aws_db_instance.My-SQL-Database[0].address
}
