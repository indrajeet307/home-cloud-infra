provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "example" {
  ami = "ami-02913db388613c3e1"
  instance_type = "t2.micro"
  
  tags = {
    name = "terraform-example"
  }
}
