resource "aws_security_group" "servers" {
  name        = "${var.aws}-${var.prefix}-aerospike"
  description = "${var.aws}-${var.prefix} Allow aerospike inbound traffic "
  vpc_id      = var.vpc_id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = var.k8s_master.cidrs
    description = "ssh"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags_all

}
