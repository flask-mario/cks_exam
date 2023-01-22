data "template_file" "master" {
  template = file(var.k8s_master.user_data_template)
  vars     = {
    worker_join        = local.worker_join
    k8s_config         = local.k8s_config
    external_ip        = aws_eip.master.public_ip
    k8_version         = var.k8s_master.k8_version
    runtime            = var.k8s_master.runtime
    utils_enable       = var.k8s_master.utils_enable
    pod_network_cidr   = var.k8s_master.pod_network_cidr
    runtime_script     = file(var.k8s_master.runtime_script)
    task_script_enable = var.k8s_master.task_script_enable
    task_script_file   = file(var.k8s_master.task_script_file)
  }
}

resource "aws_spot_instance_request" "master" {
  iam_instance_profile        = aws_iam_instance_profile.server.id
  associate_public_ip_address = "true"
  wait_for_fulfillment        = true
  ami                         = var.k8s_master.ami_id
  instance_type               = var.k8s_master.instance_type
  subnet_id                   = local.subnets[var.k8s_master.subnet_number]
  key_name                    = var.k8s_master.key_name
  security_groups             = [aws_security_group.servers.id]
  lifecycle {
    ignore_changes = [
      instance_type,
      user_data,
      root_block_device,
      key_name,
      security_groups
    ]
  }
  user_data = data.template_file.master.rendered
  tags      = local.tags_all
  root_block_device {
    volume_size           = var.k8s_master.root_volume.size
    volume_type           = var.k8s_master.root_volume.type
    delete_on_termination = true
    tags                  = local.tags_all
    encrypted             = true
  }

}

resource "aws_eip" "master" {
  vpc  = true
  tags = local.tags_all_k8_master
}

resource "aws_eip_association" "master" {
  instance_id   = aws_spot_instance_request.master.spot_instance_id
  allocation_id = aws_eip.master.id
}

resource "aws_ec2_tag" "master_ec2" {
  for_each    = local.tags_all_k8_master
  resource_id = aws_spot_instance_request.master.spot_instance_id
  key         = each.key
  value       = each.value
}

resource "aws_ec2_tag" "master_ebs" {
  for_each    = local.tags_all_k8_master
  resource_id = aws_spot_instance_request.master.root_block_device[0].volume_id
  key         = each.key
  value       = each.value
}
