data "aws_secretsmanager_secret" "workflow_manager" {
  name = "/concourse/dataworks/workflow_manager"
}

data "aws_secretsmanager_secret_version" "workflow_manager" {
  secret_id = data.aws_secretsmanager_secret.workflow_manager.id
}

variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "platform_version" {
  description = "ECS Service platform version"
  type        = string
  default     = "1.4.0"
}

variable "parent_domain_name" {
  description = "parent domain name for monitoring"
  type        = string
}

variable "whitelist_cidr_blocks" {
  description = "list of allowed cidr blocks"
  type        = list(string)
}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "2048"
}

variable "internet_proxy_port" {
  default = 3128
}

variable "https_port" {
  default = 443
}

variable "http_port" {
  default = 80
}

variable "subnets" {
  description = "define sizes for subnets using Terraform cidrsubnet function. For an empty /24 VPC, the defaults will create /28 public subnets and /26 private subnets, one of each in each AZ."
  type        = map(map(number))
  default = {
    public = {
      newbits = 4
      netnum  = 0
    }
    private = {
      newbits = 2
      netnum  = 1
    }
  }
}

variable "image_versions" {
  description = "pinned image versions to use"
  default = {
    jmx-exporter = "0.0.10"
  }
}
