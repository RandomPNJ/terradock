

variable "ava_zone" {
  type    = string
  default = "us-west-2a"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_cidrs" {
  type = list(string)
  # default = ["10.0.3.0/24", "10.0.4.0/24"]
  default = ["10.0.3.0/24"]
}

variable "private_cidrs" {
  type = list(string)
  # default = ["10.0.5.0/24", "10.0.6.0/24"]
  default = ["10.0.5.0/24"]
}

variable "access_ip" {
  type    = string
  default = "89.159.61.60/32"
}


variable "ec2_count" {
  type    = number
  default = 2
}

variable "volume_size" {
  type    = number
  default = 5
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}