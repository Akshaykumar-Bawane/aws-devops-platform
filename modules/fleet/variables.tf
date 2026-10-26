variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "bastion_sg_id" { type = string }
variable "key_pair_name" { type = string }

variable "enable" {
  type    = bool
  default = false
}

variable "node_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}