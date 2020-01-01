provider "aws" {
  region = "us-west-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
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

resource "aws_launch_configuration" "example" {
  image_id = "ami-08d489468314a58df"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id, aws_security_group.ssh.id]

  user_data = <<-EOF
              #!/bin/bash
                echo "Hello, World from $(hostname)" > index.html
                nohup python -m SimpleHTTPServer ${var.server_port} &
                EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100


  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

