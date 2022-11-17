resource "aws_security_group" "mwaa_sg" {
  name        = "mwaa-sg"
  description = "MWAA SG"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_endpoint" "mwaa_inference_endpoints" {
  for_each          = toset(["sqs", "logs", "monitoring", "kms", "ecr.api", "ecr.dkr", "codeartifact.api", "codeartifact.repositories", "airflow.api", "airflow.env", "airflow.ops"])
  vpc_id            = data.aws_vpc.selected.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.mwaa_sg.id]

  subnet_ids          = data.aws_subnets.selected.ids
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "mwaa_s3_endpoint" {
  vpc_id          = data.aws_vpc.selected.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [data.aws_route_table.selected.route_table_id]
}