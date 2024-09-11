provider "aws" {
  region = "eu-central-1"  # Region wird auf EU (Frankfurt) gesetzt
}

# VPC (Virtuelles privates Netzwerk)
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"  # Der IP-Bereich der VPC

    tags = {
        Name = "main-vpc"  # Tag, um die VPC zu identifizieren
    }
}

# Internet-Gateway für die VPC
resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id  # Verknüpft das Internet-Gateway mit der VPC

    tags = {
        Name = "main-igw"  # Tag, um das Internet-Gateway zu identifizieren
    }
}

# Öffentliches Subnetz
resource "aws_subnet" "main_public_subnet" {
    vpc_id                  = aws_vpc.main_vpc.id  # Verknüpft das Subnetz mit der VPC
    cidr_block              = "10.0.1.0/24"  # IP-Bereich des öffentlichen Subnetzes
    map_public_ip_on_launch = true  # Weist eine öffentliche IP zu

    tags = {
        Name = "main-public-subnet"  # Tag, um das Subnetz zu identifizieren
    }
}

# Routing-Tabelle für das öffentliche Subnetz
resource "aws_route_table" "main_public_rtb" {
    vpc_id = aws_vpc.main_vpc.id  # Verknüpft die Routing-Tabelle mit der VPC

    route {
        cidr_block = "0.0.0.0/0"  # Route für alle ausgehenden Verbindungen ins Internet
        gateway_id = aws_internet_gateway.main_igw.id  # Verknüpft die Route mit dem Internet-Gateway
    }

    tags = {
        Name = "main-public-rtb"  # Tag, um die Routing-Tabelle zu identifizieren
    }
}

# Verknüpfung des Subnetzes mit der Routing-Tabelle
resource "aws_route_table_association" "main_public_rtb_assoc" {
    subnet_id      = aws_subnet.main_public_subnet.id  # Verknüpft das Subnetz mit der Routing-Tabelle
    route_table_id = aws_route_table.main_public_rtb.id
}

# Sicherheitsgruppe (Security Group) für die EC2-Instanz
resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main_vpc.id  # Verknüpft die Sicherheitsgruppe mit der VPC

    # Regel: Erlaubt eingehenden HTTP-Verkehr (Port 80)
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Erlaubt Verkehr von überall
    }

    # Regel: Erlaubt eingehenden SSH-Verkehr (Port 22)
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Erlaubt SSH-Zugriff von überall
    }

    # Regel: Erlaubt ausgehenden Verkehr (alle Ports, alle Protokolle)
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"  # -1 steht für alle Protokolle
        cidr_blocks = ["0.0.0.0/0"]  # Erlaubt ausgehenden Verkehr nach überall
    }

    tags = {
        Name = "web-sg"  # Tag, um die Sicherheitsgruppe zu identifizieren
    }
}

# EC2-Instanz für die Feedback-App
resource "aws_instance" "feedback_app_instance" {
    ami           = "ami-0de02246788e4a354"  # Amazon Linux 2 AMI
    instance_type = "t2.micro"  # Instanztyp, der für kleine Anwendungen geeignet ist
    subnet_id     = aws_subnet.main_public_subnet.id  # Verknüpft die Instanz mit dem öffentlichen Subnetz
    security_groups = [aws_security_group.web_sg.name]  # Sicherheitsgruppe der Instanz

    # Userdata-Skript, das bei der Instanzerstellung ausgeführt wird (Installation von Docker und Start der App)
    user_data = file("userdata.sh")

    tags = {
        Name = "feedback-app-instance"  # Tag, um die Instanz zu identifizieren
    }
}

# Ausgabe der öffentlichen IP-Adresse der EC2-Instanz
output "instance_public_ip" {
    value = aws_instance.feedback_app_instance.public_ip  # Zeigt die öffentliche IP der Instanz an
}
