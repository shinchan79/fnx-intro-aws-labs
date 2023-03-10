output "Login" {
  value = "ssh -i yenpasona-key ec2-user@${aws_instance.ec2.public_ip}"
}

output "db_access_from_ec2" {
  value = "mysql -h ${aws_db_instance.mysql.address} -P ${aws_db_instance.mysql.port} -u ${var.username} -p${var.password}"
}

output "access" {
  value = "http://${aws_instance.ec2.public_ip}/index.php"
}
