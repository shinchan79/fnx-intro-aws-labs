variable "elasticapp" {
  default = "myapplication"
}
variable "beanstalkappenv" {
  default = "myenvironment"
}
variable "solution_stack_name" {
  default = "64bit Amazon Linux 2 v5.6.4 running Node.js 16" #  aws elasticbeanstalk list-available-solution-stacks
}
variable "tier" {
  default = "WebServer"
}
 
variable "vpc_id" {
    default = "vpc-0e002ea9920b93e82"
}
variable "public_subnets" {
    default = ["subnet-0783d40404e54a399", "subnet-0a6b9af823267035e"]
}