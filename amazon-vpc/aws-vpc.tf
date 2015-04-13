resource "aws_route53_zone" "primary" {
   name = "quietness.co"
}


provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
        region = "us-east-1"
}

resource "aws_vpc" "yourcompany_staging_vpc" {
        cidr_block = "172.16.0.0/16"
        tags {
                Name = "yourcompany_staging_vpc"
        }
}

resource "aws_internet_gateway" "yourcompany_staging_igw" {
        vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"
        tags {
                Name = "yourcompany_staging_igw"
        }
}

# NAT instance

# resource "aws_security_group" "yourcompany_staging_nat" {
# 	name = "nat"
# 	description = "Allow services from the private subnet through NAT"

# 	ingress {
# 		from_port = 0
# 		to_port = 65535
# 		protocol = "tcp"
# 		cidr_blocks = ["${aws_subnet.yourcompany_staging_east-1b-private.cidr_block}"]
# 	}
# 	ingress {
# 		from_port = 0
# 		to_port = 65535
# 		protocol = "tcp"
# 		cidr_blocks = ["${aws_subnet.yourcompany_staging_us-east-1e-private.cidr_block}"]
# 	}

#         vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"
#         tags {
#                 Name = "yourcompany_staging_nat"
#         }
# }

# resource "aws_instance" "yourcompany_staging_nat" {
# 	ami = "${var.aws_nat_ami}"
# 	availability_zone = "us-east-1b"
# 	instance_type = "m1.small"
#         key_name = "weedlabs-master"
# 	security_groups = ["${aws_security_group.yourcompany_staging_nat.id}"]
# 	subnet_id = "${aws_subnet.yourcompany_staging_east-1b-public.id}"
# 	associate_public_ip_address = true
#         source_dest_check = false
#         tags {
#                 Name = "yourcompany_staging_nat"
#         }
# }

# resource "aws_eip" "yourcompany_staging_nat" {
# 	instance = "${aws_instance.yourcompany_staging_nat.id}"
#         vpc = true
# }

# Public subnets

resource "aws_subnet" "yourcompany_staging_east-1b-public" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	cidr_block = "172.16.0.0/24"
        availability_zone = "us-east-1b"
        tags {
                Name = "yourcompany_staging_nat"
        }

}

resource "aws_subnet" "yourcompany_staging_us-east-1e-public" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	cidr_block = "172.16.2.0/24"
        availability_zone = "us-east-1e"

        tags {
                Name = "yourcompany_staging_us-east-1e-public"
        }
}

# Routing table for public subnets

resource "aws_route_table" "yourcompany_staging_us-east-1-public" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.yourcompany_staging_igw.id}"
        }
        tags {
                Name = "yourcompany_staging_us-east-1e-public"
        }
}

resource "aws_route_table_association" "yourcompany_staging_east-1b-public" {
	subnet_id = "${aws_subnet.yourcompany_staging_east-1b-public.id}"
	route_table_id = "${aws_route_table.yourcompany_staging_us-east-1-public.id}"
}

resource "aws_route_table_association" "yourcompany_staging_us-east-1e-public" {
	subnet_id = "${aws_subnet.yourcompany_staging_us-east-1e-public.id}"
	route_table_id = "${aws_route_table.yourcompany_staging_us-east-1-public.id}"
}

# Private subsets

resource "aws_subnet" "yourcompany_staging_east-1b-private" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	cidr_block = "172.16.1.0/24"
	availability_zone = "us-east-1b"
}

resource "aws_subnet" "yourcompany_staging_us-east-1e-private" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	cidr_block = "172.16.3.0/24"
	availability_zone = "us-east-1e"
}

# Routing table for private subnets

resource "aws_route_table" "yourcompany_staging_us-east-1-private" {
	vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.yourcompany_staging_bastion.id}"
        }
        tags {
                Name = "yourcompany_staging_us-east-1-private"
        }
}

resource "aws_route_table_association" "yourcompany_staging_east-1b-private" {
	subnet_id = "${aws_subnet.yourcompany_staging_east-1b-private.id}"
	route_table_id = "${aws_route_table.yourcompany_staging_us-east-1-private.id}"
}

resource "aws_route_table_association" "yourcompany_staging_us-east-1e-private" {
	subnet_id = "${aws_subnet.yourcompany_staging_us-east-1e-private.id}"
	route_table_id = "${aws_route_table.yourcompany_staging_us-east-1-private.id}"
}

# Bastion

resource "aws_security_group" "yourcompany_staging_bastion" {
	name = "yourcompany_staging_bastion"
	description = "Allow SSH traffic from the internet"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

        vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"
        tags {
                Name = "yourcompany_staging_bastion"
        }
}

resource "aws_instance" "yourcompany_staging_bastion" {
	ami = "${var.aws_ubuntu_ami}"
	availability_zone = "us-east-1b"
	instance_type = "t2.micro"
        key_name = "yourkey"
	security_groups = ["${aws_security_group.yourcompany_staging_bastion.id}"]
        subnet_id = "${aws_subnet.yourcompany_staging_east-1b-public.id}"

        tags {
                Name = "yourcompany_staging_bastion"
        }
}

resource "aws_eip" "yourcompany_staging_bastion" {
	instance = "${aws_instance.yourcompany_staging_bastion.id}"
	vpc = true
}

# Web1

resource "aws_security_group" "yourcompany_staging_web1" {
	name = "yourcompany_staging_web1"
	description = "Allow SSH traffic from the internet"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["172.16.0.0/24"]
	}

        vpc_id = "${aws_vpc.yourcompany_staging_vpc.id}"
        tags {
                Name = "yourcompany_staging_web1"
        }
}

resource "aws_instance" "yourcompany_staging_web1" {
	ami = "${var.aws_web_ami}"
	availability_zone = "us-east-1b"
	instance_type = "m1.small"
        key_name = "yourkey"
	security_groups = ["${aws_security_group.yourcompany_staging_web1.id}"]
        subnet_id = "${aws_subnet.yourcompany_staging_east-1b-public.id}"

        tags {
                Name = "yourcompany_staging_web1"
        }
}

resource "aws_eip" "yourcompany_staging_web1" {
	instance = "${aws_instance.yourcompany_staging_web1.id}"
	vpc = true
}


resource "aws_route53_record" "web1" {
   zone_id = "${aws_route53_zone.primary.zone_id}"
   name = "quietness.co"
   type = "A"
   ttl = "300"
   records = ["${aws_eip.yourcompany_staging_web1.public_ip}"]
}
