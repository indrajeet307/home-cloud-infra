provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "example" {
  ami = "ami-08d489468314a58df"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.instance.id, aws_security_group.ssh.id]
  key_name = "default-key"

  user_data = <<-EOF
              #!/bin/bash
                echo "Hello, World" > index.html
                nohup python -m SimpleHTTPServer 8080 &
                EOF

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  name = "terraform-ssh-instance"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "default" {
  key_name = "default-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSHarGPxDNLs8H7q+nsFZDMORhhR2eWzp/lVu4/EGX5nhl7CGiiIOY4VCX/v7y+VZFUtCZQAqCf2UgGIEpDyEWXmlXVt855tM7JprMPJ+txko6UtztL6p4Y4B8hkzaCEXOLLRKfW32nTNZK2LA4o8wKMS6Ppsf3xX3sCnWtjvIwZIZXnUKvhR0M8W35K59atGQ1ThAPVM/Vix0LtMePme60KldV9UukZBU283JQt6zfRNms370dcDQc6b23QuBH8hHtaZ8KMIUipEsz1RMzOtAHgxP/zG/G9j0l190h/ReNjEulel81uX3jsgLtLJdcw86fegM6Gsth+Xw2xW8B9Xz indrajeet@xps"

}
