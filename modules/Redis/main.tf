resource "aws_security_group" "redis" {
  name_prefix = "qa-redis-sg-"
  description = "Allow redis traffic within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = "default.redis7"
  engine_version       = var.engine_version
  port                 = 6379
  subnet_group_name    = var.redis_subnet_group_name
  depends_on = [ aws_security_group.redis ]
  security_group_ids   = ["${aws_security_group.redis.id}"]
  
}