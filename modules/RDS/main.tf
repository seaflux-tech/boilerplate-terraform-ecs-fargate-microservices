resource "random_password" "master_password" {
  length  = 10
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "${var.environment}-rds-example-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.master_password.result
  })
}


resource "aws_rds_cluster_instance" "example" {
    identifier             = var.db_name
    cluster_identifier     = aws_rds_cluster.example.cluster_identifier
    engine                 = "aurora-mysql"
    engine_version         = var.db_engine_version
    instance_class         = var.db_instance_class
    db_subnet_group_name   = var.db_subnet_group_name
  }

resource "aws_security_group" "RDS" {
  name_prefix = "qa-RDS-sg-"
  description = "Allow redis traffic within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
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

resource "aws_rds_cluster" "example" {
  cluster_identifier      = var.db_name
  engine                  = "aurora-mysql"
  engine_version          = var.db_engine_version
  # availability_zones      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]  
  database_name           = var.db_name
  master_username         = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["username"]
  master_password         = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["password"]
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = ["${aws_security_group.RDS.id}"]
  skip_final_snapshot     = true  
  storage_encrypted       = true
}