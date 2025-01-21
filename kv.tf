data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "george-aks-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "current_user_secret_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv1" {
  name                  = "pdznl-vault-cac-001"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones["kv_dns_zone"].name
  virtual_network_id    = azurerm_virtual_network.vnet_aks.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv2" {
  name                  = "pdznl-vault-cac-002"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones["kv_dns_zone"].name
  virtual_network_id    = azurerm_virtual_network.vnet_hub.id
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-vault-cac-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pep.id

  private_service_connection {
    name                           = "psc-vault-cac-001"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-vault-cac-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zones["kv_dns_zone"].id]
  }
}
