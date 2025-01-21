resource "azurerm_private_dns_zone" "dns_zones" {
  for_each            = var.private_dns_zones
  name                = each.value["name"]
  resource_group_name = azurerm_resource_group.rg.name
}