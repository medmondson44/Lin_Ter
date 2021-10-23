resource "linode_sshkey" "ssh_key" {
  label       = "Dev SSH Key"
  ssh_key = chomp(file("/home/terransible/devops_hacker_infra/my_project/devops.pub"))
}

resource "linode_instance" "my-ubuntu" {
        image = "linode/ubuntu20.04"
        label = "my-ubuntu-terraform"
        group = "Terraform"
        region = "us-east"
        type = "g6-nanode-1"
        root_pass = "<placeholder>"
        authorized_keys = [linode_sshkey.ssh_key.ssh_key]
        connection {
            host = self.ip_address
            user = "root"
            type = "ssh"
            agent = false
            timeout = "3m"
            private_key = file("/home/terransible/devops_hacker_infra/my_project/devops")
  }

        provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo adduser --disabled-password --gecos '' ansible",
      "sudo mkdir -p /home/ansible/.ssh",
      "sudo touch /home/ansible/.ssh/authorized_keys",
      "sudo echo '${file("/home/terransible/devops_hacker_infra/my_project/devops.pub")}' > authorized_keys",
      "sudo mv authorized_keys /home/ansible/.ssh",
      "sudo chown -R ansible:ansible /home/ansible/.ssh",
      "sudo chmod 700 /home/ansible/.ssh",
      "sudo chmod 600 /home/ansible/.ssh/authorized_keys",
      "sudo usermod -aG sudo ansible",
      "sudo echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers"
    ]
  }
        
}

resource "linode_firewall" "my-firewall" {
  label = "my-firewall"
  tags  = ["test"]

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound_policy = "DROP"
  outbound_policy = "ACCEPT"
  linodes = [linode_instance.my-ubuntu.id]
}