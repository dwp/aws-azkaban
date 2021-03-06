{
  "cpu": ${cpu},
  "image": "${image_url}",
  "memory": ${memory},
  "name": "${name}",
  "networkMode": "awsvpc",
  "user": "${user}",
  "portMappings": ${jsonencode([
    for port in jsondecode(ports) : {
      containerPort = port,
      hostPort = port
    }
  ])},
  "mountPoints": ${jsonencode([
    for mount in jsondecode(mount_points) : {
      containerPath = mount.container_path,
      sourceVolume = mount.source_volume
    }
  ])},
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${log_group}",
      "awslogs-region": "${region}",
      "awslogs-stream-prefix": "${name}"
    }
  },
  "placementStrategy": [
    {
      "field": "attribute:ecs.availability-zone",
      "type": "spread"
    }
  ],
  "environment": ${jsonencode(concat([
      {
        "name": join("", [upper(group_name), "_CONFIG_S3_BUCKET"]),
        "value": config_bucket
      },
      {
        "name": join("", [upper(group_name), "_CONFIG_S3_PREFIX"]),
        "value": "workflow-manager/${group_value}"
      }
    ],
    [
      for variable in jsondecode(environment_variables) : {
        name = variable.name,
        value = variable.value
      }
    ]
  ))}
}
