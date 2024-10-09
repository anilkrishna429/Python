# Define the AWS provider configuration.
provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region.
}

variable "cidr" {
  default = "10.1.0.0/24"
}

resource "aws_key_pair" "example" {
  key_name   = "terraform_dummy"  # Replace with your desired key name
  #public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public key file
  public_key = file("Downloads/terraform_dummy")
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.1.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-047d7c33f6e7b4bc4"
  instance_type          = "t2.micro"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id

  connection {
    type        = "ssh"
    user        = "ec2-user"  # Replace with the appropriate username for your EC2 instance
    private_key = file("Downloads/terraform_dummy")  # Replace with the path to your private key
    host        = self.public_ip
  }


    # The remote-exec provisioner in Terraform is designed to execute commands on a remote machine, typically an instance that Terraform has just created or modified. 
    # This provisioner connects to the remote instance using SSH (or WinRM for Windows instances) and runs the specified commands
    # The remote-exec provisioner runs commands on the remote instance. It requires the connection block to specify how to connect
    # Commands in the inline array run sequentially
    # Any failure in these commands will cause the Terraform run to fail unless specific handling is added

    provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ec2-user",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }



  ## This local-exec provisioner runs a simple echo command that appends a message to a local log file named instance_creation.log. 
  ## This happens on the local machine where Terraform is running.

   provisioner "local-exec" {
    command = "echo 'EC2 instance has been created or modified' >> instance_creation.log"
  }

    ## Here, we use a "heredoc" syntax (<<EOT ... EOT) to execute multiple commands in sequence.
    provisioner "local-exec" {
     command =  <<EOT

      #### You can run local scripts to perform tasks such as updating configuration files, triggering deployments, or sending notifications
       "sh ./scripts/notify.sh"  
      
       ##### You might want to send an email or a Slack message after an instance is created
       "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"EC2 instance created with ID: ${self.id}\"}' https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"  
       
       #### You could update local configuration files or environment variables based on the output from Terraform
        "sed -i 's/INSTANCE_ID/${self.id}/g' ./config/deployment.yaml"  
       
       #### #  The ${self.id} and ${self.public_ip} are placeholders that get replaced with the actual instance ID and public IP address of the EC2 instance being created
        echo "Instance ID: ${self.id}" >> instance_creation.log 
        echo "Instance details:" >> instance_creation.log   
        echo "Public IP: ${self.public_ip}" >> instance_creation.log

        EOT

    }



  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "E:/Devops_Notes/Terraform/provisioners/app.py"  # Replace with the path to your local file
    destination = "/home/ec2-user/app.py"  # Replace with the path on the remote instance
  }
  
 # Copies the string in content into /tmp/file.log
  provisioner "file" {
    content     = "ami used: ${self.ami}"
    destination = "/tmp/file.log"
  }

 
}

