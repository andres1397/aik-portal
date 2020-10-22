 
output "URL" {
  value = aws_lb.load-balancer[0].dns_name
}
output "DBname" {
  value = aws_db_instance.My-SQL-Database[0].name
}