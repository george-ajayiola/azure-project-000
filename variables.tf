variable "resourcegroup_name" {
  type        = string
  description = "The name of the resource group"
  default     = "testrg"
}

variable "location" {
  type        = string
  description = "The region for the deployment"
  default     = "eastus2"
}

variable "aks_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "test-api-cluster"
}

variable "aks_version" {
  description = "The version of the AKS cluster"
  type        = string
  default     = "1.30.3"
}

 variable "appgw_subnet_name" {
   type        = string
   description = "Name of the subset."
   default     = "appgwsubnet"
 }
  variable "app_gateway_subnet_address_prefix" {
   type        = string
   description = "Subnet address prefix."
   default     = "10.1.4.0/24"
 }

 variable "app_gateway_name" {
   description = "Name of the Application Gateway"
   type        = string
   default     = "ApplicationGateway1"
 }

 variable "app_gateway_tier" {
   description = "Tier of the Application Gateway tier."
   type        = string
   default     = "Standard_v2"
 }
variable "tags" {
  type        = map(string)
  description = "Tags used for the deployment"
  default = {
    "Environment" = "Lab"
    "Owner"       = "George"
  }
}

variable "private_dns_zones" {
  description = "private dns zones"
  type = map(any)
  default = {
    acr_dns_zone = {
      name                = "privatelink.azurecr.io"
    }
    kv_dns_zone = {
      name                = "privatelink.vaultcore.net"
    }
    aks_dns_zone = {
      name                = "privatelink.eastus2.azmk8s.io"
    }
  
  }
}


