provider "aws" {
  access_key = "*************************"
  secret_key = "******************************"
  region     = "us-west-2"
}

# Launch two instances and install apache and tomcat

resource "aws_instance" "web1" {
  ami = "ami-4e79ed36"
  instance_type = "t2.micro"
  key_name="aws"
  security_groups=["launch-wizard-1"]
  tags{
    Name="cas01"
  }
 connection {
  user = "ubuntu"
  type = "ssh"
  private_key="${file("/home/ubuntu/aws.pem")}"
  }
 provisioner "remote-exec" {
    inline = [
        "sudo apt-get update",
        "sudo apt-get install tomcat7 -y",
     ]
  }
 }
resource "aws_instance" "web2" {
  ami = "ami-4e79ed36"
  instance_type = "t2.micro"
  key_name="aws"
  security_groups=["launch-wizard-1"]
  tags{
    Name="cas02"
  }
 connection {
  user = "ubuntu"
  type = "ssh"
  private_key="${file("/home/ubuntu/aws.pem")}"
  }
provisioner "remote-exec" {
    inline = [
        "sudo apt-get update",
        "sudo apt-get install apache2 -y",
      ]
  }
 }

# Create security group for ELB

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating  ELB

 resource "aws_elb" "elb1" {
  name = "terraform-elb"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
  
  # Attache two instances to ELB
  
  instances = ["${aws_instance.web1.id}","${aws_instance.web2.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
  Name = "terraform-elb"
  }
}

