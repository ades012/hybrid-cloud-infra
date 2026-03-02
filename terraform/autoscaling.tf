# Balikin gembok SSH lu yang kemaren ikut kehapus
resource "aws_key_pair" "deployer" {
  key_name   = "hybrid-cloud-key-ha"
  public_key = file("~/.ssh/delz.pem.pub") # Sesuaikan path-nya kayak kemaren
}

# Bikin Security Group khusus buat EC2 di dalem ASG
resource "aws_security_group" "asg_sg" {
  name        = "hybrid-cloud-asg-sg"
  description = "Allow web traffic ONLY from ALB, and SSH from anywhere"
  vpc_id      = aws_vpc.main.id

  # Cuma nerima traffic port 80 dari Load Balancer (Gak bisa ditembak langsung dari internet)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Buka SSH buat lu troubleshooting
  ingress {
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
}

# Tarik data Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template (Ini cetakan / resep buat Auto Scaling kalau mau bikin server baru)
resource "aws_launch_template" "web_lt" {
  name_prefix   = "hybrid-cloud-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  network_interfaces {
    security_groups             = [aws_security_group.asg_sg.id]
    associate_public_ip_address = true
  }

  # Script otomatis buat ngebuktiin server mana yang lagi ngerespons
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              echo "<h1>🚀 High Availability Active! Lu lagi ngakses server dengan IP: $(hostname -I)</h1>" | sudo tee /var/www/html/index.html
              EOF
  )
}

# Auto Scaling Group (Mandor yang ngatur jumlah server)
resource "aws_autoscaling_group" "web_asg" {
  # Disebar ke 2 AZ biar kebal badai
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  # Aturan jumlah server
  desired_capacity = 2
  min_size         = 1
  max_size         = 3

  # Masukin server-server yang baru lahir ini ke tempat parkirnya ALB
  target_group_arns = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "hybrid-cloud-asg-worker"
    propagate_at_launch = true
  }
}
