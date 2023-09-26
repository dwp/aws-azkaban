resource "aws_cloudwatch_metric_alarm" "user_executor_running_tasks_less_than_desired" {
  count               = local.azkaban_user_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_user_executor_running_tasks_less_than_desired
  alarm_description   = "Managed by ${local.common_tags.DWX_Application} repository"
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-user-executor-desired-task-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

# Web monitoring
resource "aws_cloudwatch_metric_alarm" "user_web_running_tasks_less_than_desired" {
  count               = local.azkaban_user_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_user_web_running_tasks_less_than_desired
  alarm_description   = "Managed by ${local.common_tags.DWX_Application} repository"
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-user-web-desired-task-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "user_web_healthy_hosts_less_than_running_tasks" {
  count               = local.azkaban_user_alert_on_unhealthy_hosts_less_than_running[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_user_web_unhealthy_hosts
  alarm_description   = "Managed by ${local.common_tags.DWX_Application} repository"
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
        TargetGroup  = aws_lb_target_group.azkaban_webserver.arn_suffix
        LoadBalancer = aws_lb.workflow_manager.arn_suffix
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-user-healthy-vs-running",
      notification_type = "Warning",
      severity          = "High"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "user_web_healthy_hosts_zero_but_running_tasks" {
  count               = local.azkaban_user_alert_on_unhealthy_hosts_less_than_running[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_user_web_zero_unhealthy_hosts
  alarm_description   = "Managed by ${local.common_tags.DWX_Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  treat_missing_data  = "breaching"
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 == 0 && m2 >= 1, 1, 0)"
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
        TargetGroup  = aws_lb_target_group.azkaban_webserver.arn_suffix
        LoadBalancer = aws_lb.workflow_manager.arn_suffix
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
        ServiceName = aws_ecs_service.azkaban_webserver.name
        ClusterName = local.azkaban_user_ecs_cluster.name
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-user-zero-healthy-hosts",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "user_web_5xx_errors" {
  count               = local.azkaban_user_alert_on_500_errors[local.environment] ? 1 : 0
  alarm_name          = local.azkaban_user_web_5xx_errors
  comparison_operator = "GreaterThanThreshold"
  threshold           = "10"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"

  dimensions = {
    LoadBalancer = aws_lb.workflow_manager.arn_suffix
  }

  alarm_description = "This metric monitors 5xx errors on Azkaban user LB"
  alarm_actions     = [local.monitoring_topic_arn]

  tags = merge(
    local.common_tags,
    {
      Name              = "azkaban-user-5xx-alert",
      notification_type = "Warning",
      severity          = "Critical"
    },
  )
}
