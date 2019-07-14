data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "${local.name_prefix}-main"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 1 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${local.name_prefix}-public"
  }
  count = 2
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 1 + length(aws_subnet.public) + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${local.name_prefix}-private"
  }
  count = 2
}

# VPC SGs
# TODO
# Looks like really only public needs to be `registry` and `web`, and they need
# 3000 and 3001 per docker-compose, but if we're just deploying beanstalk
# containers I'm not sure how that applies. Also if those ports should be
# changed since it's not a "dev" setup.

# RDS
resource "aws_db_subnet_group" "db" {
  name       = "main"
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "${local.name_prefix} - private subnets"
  }
}

resource "aws_db_instance" "db" {
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "10.1"
  instance_class       = "db.t2.micro" # TODO
  name                 = "entropic_dev"
  username             = "postgres"
  password             = "raccoon-means-one-who-scrubs-with-its-hands"
  db_subnet_group_name = aws_db_subnet_group.db.name

  allocated_storage     = 5
  max_allocated_storage = 100
  apply_immediately     = var.dev_mode
}

# Cache
resource "aws_elasticache_cluster" "redis" {
  cluster_id        = "${local.name_prefix}-cache"
  engine            = "redis"
  node_type         = "cache.t2.micro" # TODO
  num_cache_nodes   = 1
  engine_version    = "5.0.4"
  port              = 6379
  apply_immediately = var.dev_mode
}


# Elastic beanstalk

# beanstalkd
# registry
# web
# storage
