variable "project_name" {
  type        = string
  description = "Project name variable"
}
# Location variables
variable "region" {
  type        = string
  description = "Region variable"
}

variable "zone" {
  type        = string
  description = "Zone variable"
}

# VPC variables
variable "vpc_name" {
  type        = string
  default     = "my-vpc"
  description = "Resource VPC name"
}

# Subnet variables
variable "subnet_name" {
  type        = string
  default     = "my-subnet"
  description = "Resource Subnet name"
}

# Router variables
variable "router_name" {
  type        = string
  default     = "my-router"
  description = "Resource Router name"
}

# Router NAT variables
variable "router_nat_name" {
  type        = string
  default     = "my-router-nat-name"
  description = "Resource Router NAT name"
}

# Address variables
variable "address_name" {
  type        = string
  default     = "my-address-name"
  description = "Resource Address name"
}

# Firewall
variable "firewall_name" {
  type        = string
  default     = "my-firewall"
  description = "Resource Firewall name"
}

variable "firewall_allow_ports" {
  type        = list(any)
  default     = ["22"]
  description = "Resource Firewall allow tcp list ports"
}

# Cluster variables
variable "cluster_name" {
  type        = string
  default     = "my-cluster"
  description = "Resource Cluster name"
}

# Node pool variables
variable "node_machine_type" {
  type        = string
  default     = "e2-medium"
  description = "Resource Node pool machine type"
}

