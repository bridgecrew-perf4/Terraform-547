# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = "AKIAIHE5K7FH6XIXEKDA"
  secret_key = "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"
}


#..........  Create VPC   ...........

resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "Production"
  }
}

#........... Internet Gateway  ...........

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpc.id

}

#........... Route table  ...........

resource "aws_route_table" "routable" {
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route table Prod"
  }
}

#...........  Subnet  .........


resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prodvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Production VPC"
  }
}

#......... subnest Asociation .........

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routable.id
}

#................  Security Group   ................

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prodvpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


   ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#...... Network Interface

resource "aws_network_interface" "Prodinterface1" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_network_interface" "Prodinterface2" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.49"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_network_interface" "Prodinterface3" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.48"]
  security_groups = [aws_security_group.allow_web.id]

}
#.......   Assign elastic public ip adress  ..................

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.Prodinterface1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.Prodinterface2.id
  associate_with_private_ip = "10.0.1.49"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_eip" "three" {
  vpc                       = true
  network_interface         = aws_network_interface.Prodinterface3.id
  associate_with_private_ip = "10.0.1.48"
  depends_on                = [aws_internet_gateway.gw]
}
#..................  Create Instance  .........................

 resource "aws_instance" "load_balancer_ansible" {
  ami           = "ami-07a0844029df33d7d"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "main-key"

  network_interface {
     device_index = 0
     network_interface_id = aws_network_interface.Prodinterface1.id
  }

  tags = {
    Name = "load_balancer"
    }        
 }

 resource "aws_instance" "ansible_1" {
  ami           = "ami-07a0844029df33d7d"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "main-key"

  network_interface {
     device_index = 0
     network_interface_id = aws_network_interface.Prodinterface2.id
  }

  tags = {
    Name = "ansible1"
    }        
 }

  resource "aws_instance" "ansible_2" {
  ami           = "ami-07a0844029df33d7d"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "main-key"

  network_interface {
     device_index = 0
     network_interface_id = aws_network_interface.Prodinterface3.id
  }

  tags = {
    Name = "ansible2"
    }        
 }

# output ... server public ip ...

output "server_Plublic_IP_Output_only" {
value = {ip_load_balancer = aws_eip.one.public_ip,
         ip_ansible_1 = aws_eip.two.public_ip,
         ip_ansible_2 = aws_eip.three.public_ip

  }
}
