resource "aws_cloudwatch_metric_alarm" "external_executor_running_tasks_less_than_desired" {
  count               = local.azkaban_external_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_external_executor_running_tasks_less_than_desired
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
        ClusterName = local.azkaban_external_ecs_cluster.name
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
        ClusterName = local.azkaban_external_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-executor-desired-task-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

# Web monitoring
resource "aws_cloudwatch_metric_alarm" "external_web_running_tasks_less_than_desired" {
  count               = local.azkaban_external_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_external_web_running_tasks_less_than_desired
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
        ServiceName = aws_ecs_service.azkaban_external_webserver.name
        ClusterName = local.azkaban_external_ecs_cluster.name
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
        ServiceName = aws_ecs_service.azkaban_external_webserver.name
        ClusterName = local.azkaban_external_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-web-desired-task-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "external_web_healthy_hosts_less_than_running_tasks" {
  count               = local.azkaban_alert_on_unhealthy_hosts_less_than_running[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_external_web_unhealthy_hosts
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  treat_missing_data  = "breaching"
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 < m2, 1, 0)"
    label       = "HealthyHostDisparity"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        TargetGroup  = aws_lb_target_group.azkaban_external_webserver.arn_suffix
        LoadBalancer = aws_lb.azkaban_external.arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        ServiceName = aws_ecs_service.azkaban_external_webserver.name
        ClusterName = local.azkaban_external_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-healthy-vs-running",
      notification_type = "Warning",
      severity          = "High"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "external_web_healthy_hosts_zero_but_running_tasks" {
  count               = local.azkaban_alert_on_unhealthy_hosts_less_than_running[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_external_web_zero_unhealthy_hosts
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  treat_missing_data  = "breaching"
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 == 0 && m2 > 1, 1, 0)"
    label       = "NoHealthyHosts"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        TargetGroup  = aws_lb_target_group.azkaban_external_webserver.arn_suffix
        LoadBalancer = aws_lb.azkaban_external.arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        ServiceName = aws_ecs_service.azkaban_external_webserver.name
        ClusterName = local.azkaban_external_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-zero-healthy-hosts",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "external_web_5xx_errors" {
  alarm_name          = "External Web 5xx errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"

  dimensions = {
    LoadBalancer = aws_lb.azkaban_external.arn_suffix
  }

  alarm_description = "This metric monitors 5xx errors on Azkaban external LB"
  alarm_actions     = [local.monitoring_topic_arn]

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-external-5xx-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}
