# Bikin Security Group buat Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "hybrid-cloud-alb-sg"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bikin Application Load Balancer (ALB)
resource "aws_lb" "web_alb" {
  name               = "hybrid-cloud-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # ALB ini bakal disebar kakinya ke 2 Subnet di 2 AZ berbeda!
  subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Bikin Target Group (Tempat parkir server-server EC2 nanti)
resource "aws_lb_target_group" "web_tg" {
  name     = "hybrid-cloud-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

# Bikin Listener (Telinga ALB buat dengerin request port 80)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Output DNS Name dari Load Balancer (Ini yang bakal lu akses di browser nanti)
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
