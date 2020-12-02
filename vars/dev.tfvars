project         = "bus-backend-infra"
env             = "dev"
region          = "ap-southeast-1"
cidr_block      = "10.0.0.0/16"
public_subnets  = ["10.0.32.0/20", "10.0.96.0/20"]
private_subnets = ["10.0.0.0/19", "10.0.64.0/19"]
azs             = ["ap-southeast-1a", "ap-southeast-1b"]
www_domain_name = "dev.sgbus.tk"