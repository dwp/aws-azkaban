resource "aws_cloudwatch_metric_alarm" "external_running_tasks_less_than_desired" {
  count               = local.azkaban_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_external_running_tasks_less_than_desired
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  treat_missing_data  = "breaching"
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 < m2, 1, 0)"
    label       = "DesiredCountNotMet"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        ServiceName = aws_ecs_service.azkaban_executor.name
        ClusterName = aws_ecs_service.azkaban_executor.cluster
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        ServiceName = aws_ecs_service.azkaban_executor.name
        ClusterName = aws_ecs_service.azkaban_executor.cluster
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-desired-task-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}
