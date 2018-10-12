/* Setup our aws provider */
provider "aws" {
  version = "~> 1.8"
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}
resource "aws_instance" "master" {
  ami           = "ami-054266d2576775c8e"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "ec2-user"
    private_key = "${file("ssh/key")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",	  
	  "sudo rpm --import \"https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e\"",
	  "sudo yum install -y yum-utils",
	  "sudo yum-config-manager --add-repo https://packages.docker.com/1.13/yum/repo/main/centos/7",
	  "sudo sh -c 'echo \"deb https://apt.dockerproject.org/repo ubuntu-trusty main\" > /etc/apt/sources.list.d/docker.list'",
	  "sudo yum makecache fast",
	  "sudo yum install -y docker-engine",
	  "sudo service docker start",
	  "sudo docker swarm init",
      "sudo docker swarm join-token --quiet worker > /home/ec2-user/token"
	  
    ]
  }
  provisioner "file" {
    source = "proj"
    destination = "/home/ec2-user/"
  }
  tags = { 
    Name = "swarm-master"
  }
}

resource "aws_instance" "slave" {
  count         = 2
  ami           = "ami-054266d2576775c8e"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "ec2-user"
    private_key = "${file("ssh/key")}"
  }
  provisioner "file" {
    source = "key"
    destination = "/home/ec2-user/key"
  }
    provisioner "remote-exec" {
    inline = [
	
	  "sudo yum update -y",	  
	  "sudo yum install -y yum-utils",
	  "sudo rpm --import \"https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e\"",
	  "sudo yum-config-manager --add-repo https://packages.docker.com/1.13/yum/repo/main/centos/7",
	  "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "sudo sh -c 'echo \"deb https://apt.dockerproject.org/repo ubuntu-trusty main\" > /etc/apt/sources.list.d/docker.list'",
      "sudo yum makecache fast",
	  "sudo yum install -y docker-engine",	   
	   
	  "sudo service docker start",	 
	  "sudo clear",
	  "sudo ls /home/ec2-user/",
	  "ssh-keygen -y -f /home/ec2-user/key",
	  "sudo chmod 400 /home/ec2-user/key",	
	  "ssh-keygen -p -F /home/ec2-user/key", 
      "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/ec2-user/key ec2-user@${aws_instance.master.private_ip}:/home/ec2-user/token .",
      "sudo ls /home/ec2-user/",
	  "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.master.private_ip}:2377"
	 
	  
    ]
  }

  tags = { 
    Name = "swarm-${count.index}"
  }
}
