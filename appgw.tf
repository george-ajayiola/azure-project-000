 # Locals block for hardcoded names
 locals {
   backend_address_pool_name      = "${azurerm_virtual_network.vnet_aks.name}-beap"
   frontend_port_name             = "${azurerm_virtual_network.vnet_aks.name}-feport"
   frontend_ip_configuration_name = "${azurerm_virtual_network.vnet_aks.name}-feip"
   http_setting_name              = "${azurerm_virtual_network.vnet_aks.name}-be-htst"
   listener_name                  = "${azurerm_virtual_network.vnet_aks.name}-httplstn"
   request_routing_rule_name      = "${azurerm_virtual_network.vnet_aks.name}-rqrt"
 }


 resource "azurerm_public_ip" "appgw-pip" {
   name                = "appgw-public-ip"
   resource_group_name = azurerm_resource_group.rg.name
   location            = azurerm_resource_group.rg.location
   allocation_method   = "Static"
   sku                 = "Standard"
 }

resource "azurerm_application_gateway" "appgw" {
   name                = var.app_gateway_name
   resource_group_name = azurerm_resource_group.rg.name
   location            = azurerm_resource_group.rg.location

   sku {
     name     = var.app_gateway_tier
     tier     = var.app_gateway_tier
     capacity = 1
   }

   gateway_ip_configuration {
     name      = "appGatewayIpConfig"
     subnet_id = azurerm_subnet.appgw.id
   }

   frontend_port {
     name = local.frontend_port_name
     port = 80
   }

   frontend_ip_configuration {
     name                 = local.frontend_ip_configuration_name
     public_ip_address_id = azurerm_public_ip.appgw-pip.id
   }

   backend_address_pool {
     name = local.backend_address_pool_name
   }

   backend_http_settings {
     name                  = local.http_setting_name
     cookie_based_affinity = "Disabled"
     port                  = 80
     protocol              = "Http"
     request_timeout       = 1
   }

   http_listener {
     name                           = local.listener_name
     frontend_ip_configuration_name = local.frontend_ip_configuration_name
     frontend_port_name             = local.frontend_port_name
     protocol                       = "Http"
   }

   request_routing_rule {
     name                       = local.request_routing_rule_name
     priority                   = 1
     rule_type                  = "Basic"
     http_listener_name         = local.listener_name
     backend_address_pool_name  = local.backend_address_pool_name
     backend_http_settings_name = local.http_setting_name
   }

   lifecycle {
     ignore_changes = [
       tags,
       backend_address_pool,
       backend_http_settings,
       http_listener,
       probe,
       request_routing_rule,
     ]
   }
 }