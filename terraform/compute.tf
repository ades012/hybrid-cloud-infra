# Daftarin Public Key lu ke AWS
resource "aws_key_pair" "deployer" {
  key_name   = "hybrid-cloud-key"
  public_key = file("~/.ssh/delz.pem.pub") # Sesuaikan path dan nama file kalau lu pake id_rsa.pub
}

# Bikin Security Group (Firewall buat EC2)
resource "aws_security_group" "web_sg" {
  name        = "hybrid-cloud-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Buka port 80 buat akses web aplikasi
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Buka port 22 buat akses SSH (Ganti IP di bawah sama IP Public Indihome/ISP lu kalau mau aman banget)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Buka semua port buat traffic keluar
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hybrid-cloud-sg"
  }
}

# Tarik data Ubuntu 22.04 AMI (Image OS) otomatis dari AWS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Owner ID resmi Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bikin EC2 Instance (Server-nya)
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # Free tier / murah meriah
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = aws_key_pair.deployer.key_name

  # Script ini bakal dijalanin otomatis pas server pertama kali nyala (Install Docker)
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y ca-certificates curl
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "hybrid-cloud-worker-node"
  }
}

# Outputin Public IP-nya biar gampang dicari
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}