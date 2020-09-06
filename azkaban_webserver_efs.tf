resource "aws_efs_file_system" "azkaban_webserver" {
  tags = merge(local.common_tags, { Name = "azkaban-webserver-efs" })
}

resource "aws_efs_mount_target" "azkaban_webserver" {
  count           = length(aws_subnet.workflow_manager_private)
  file_system_id  = aws_efs_file_system.azkaban_webserver.id
  subnet_id       = aws_subnet.workflow_manager_private[count.index].id
  security_groups = [aws_security_group.azkaban_webserver_efs.id]
}

resource "aws_efs_access_point" "azkaban_webserver" {
  file_system_id = aws_efs_file_system.azkaban_webserver.id
  root_directory {
    path = "/azkaban-webserver-data"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 600
    }
  }
  posix_user {
    uid = 0
    gid = 0
  }
}

resource "aws_security_group" "azkaban_webserver_efs" {
  name        = "azkaban-webserver-efs"
  description = "Rules necesary for accessing EFS"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-webserver-efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_azkaban_webserver" {
  description              = "Allow azkaban webserver to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.azkaban_webserver_efs.id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.azkaban_webserver.id
}
