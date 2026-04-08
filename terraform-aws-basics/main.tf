provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.1.0.0/16"
        tags = {
        Name = "tf-yaic-vpc"
    }
}

