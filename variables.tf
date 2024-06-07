variable "image_id" {
  type    = string
  default = "ami-0e001c9271cf7f3b9"
}

variable "size" {
  type    = string
  default = "t2.micro"
}

variable "key" {
  type    = string
  default = "sayeed"
}

variable "db_identifier" {
  type    = string
  default = "database-1"
}

variable "db_engine" {
  type    = string
  default = "mysql"
}


variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "webserver"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type    = string
  default = "webserver"
}

variable "db_parameter_group_name" {
  type    = string
  default = "default.mysql8.0"
}
