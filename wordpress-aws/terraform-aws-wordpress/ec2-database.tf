resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = "db.t3.micro"
  db_name                   = var.dbname
  username               = var.username
  password               = var.password
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.mysql.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  skip_final_snapshot    = true
}

resource "aws_instance" "ec2" {
  ami           = "ami-062f8fd8345beef36"
  instance_type = "t3.micro"

  depends_on = [
    aws_db_instance.mysql,
  ]

  key_name                    = "yen"
  vpc_security_group_ids      = [aws_security_group.web.id]
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
}

resource "aws_db_snapshot" "test" {
  db_instance_identifier = aws_db_instance.mysql.id
  db_snapshot_identifier = "testsnapshot1234"
}