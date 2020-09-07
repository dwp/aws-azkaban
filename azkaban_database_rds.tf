resource "aws_db_instance" "azkaban_database" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.azkaban_database.name
  vpc_security_group_ids = [aws_security_group.azkaban_database.id]
  name                   = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_name
  username               = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_username
  password               = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_password
  parameter_group_name   = "default.mysql5.7"
  tags                   = merge(local.common_tags, { Name = "azkaban-database" })
}

resource "aws_db_subnet_group" "azkaban_database" {
  name       = "azkaban-database"
  subnet_ids = aws_subnet.workflow_manager_private.*.id
  tags       = merge(local.common_tags, { Name = "azkaban-database" })
}
