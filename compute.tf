
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "main_ec2" {
  for_each          = aws_subnet.public_subnet
  ami               = data.aws_ami.server_ami.id
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.ec2_auth.id
  availability_zone = local.azs[index(keys(aws_subnet.public_subnet), each.key) + 1]

  vpc_security_group_ids = [aws_security_group.main_ec2_sg.id]
  subnet_id              = each.value.id
#   user_data              = templatefile("./main-userdata.tpl", { new_hostname = "mtc-main-${random_id.rdm_id.dec}" })
  root_block_device {
    volume_size = var.volume_size
  }

    provisioner "local-exec" {
        command = "printf '\n${self.public_ip}' >> host_file"
    }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '' '/${self.public_ip}/d' host_file"
  }

  tags = {
    "Name" = "main_ec2-${index(keys(aws_subnet.public_subnet), each.key) + 1}"
  }
}

# resource "null_resource" "grafana_update" {
#   for_each = aws_subnet.public_subnet

#   provisioner "remote-exec" {
#     inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I upgraded grafana' >> upgrade.log"]
#   }

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("./ec2-key")
#     host        = aws_instance.main_ec2[each.key].public_ip
#   }
# }

resource "null_resource" "ansible_provisioning" {
    depends_on = [
      aws_instance.main_ec2
    ]

    provisioner "local-exec" {
        command = "ansible-playbook -i ./host_file --key-file ./ec2-key ./playbooks/main.yml"
    }
}
resource "aws_key_pair" "ec2_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}