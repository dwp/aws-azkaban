resource "aws_subnet" "azkaban_public" {
  count                = length(data.aws_availability_zones.current.zone_ids)
  cidr_block           = cidrsubnet(local.cidr_block[local.environment].workflow-manager-vpc, var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id               = module.workflow_manager_vpc.vpc.id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public-${data.aws_availability_zones.current.names[count.index]}" })
}

resource "aws_internet_gateway" "igw_azkaban_external" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public" })
}

resource "aws_route_table" "azkaban_external_public" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_azkaban_external.id
  }
}

resource "aws_route_table_association" "azkaban_external_subnet" {
  count          = length(data.aws_availability_zones.current.zone_ids)
  subnet_id      = aws_subnet.azkaban_public[count.index].id
  route_table_id = aws_route_table.azkaban_external_public.id
}
