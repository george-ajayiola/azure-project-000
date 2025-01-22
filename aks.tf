resource "azurerm_resource_group" "rg" {
  name     = var.resourcegroup_name
  location = var.location
  tags     = var.tags
}
# DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "aks1" {
  name                  = "pdzvnl-aks-cac-001"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones["aks_dns_zone"].name
  virtual_network_id    = azurerm_virtual_network.vnet_hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks2" {
  name                  = "pdzvnl-aks-cac-002"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones["aks_dns_zone"].name
  virtual_network_id    = azurerm_virtual_network.vnet_aks.id
}

# Managed identities
data "azurerm_user_assigned_identity" "ingress" {
  name                = "ingressapplicationgateway-${azurerm_kubernetes_cluster.mycluster.name}"
  resource_group_name = azurerm_kubernetes_cluster.mycluster.node_resource_group
}

resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.rg.location
  name                = "id-uami-controlplane"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "workload_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "id-uami-workloadidentity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = azurerm_resource_group.rg.location
  name                = "id-uami-kubelet"
  resource_group_name = azurerm_resource_group.rg.name
}

# Managed identity role assignments
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "secret_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  }

 # Role assignments
 resource "azurerm_role_assignment" "ra1" {
   scope                = azurerm_resource_group.rg.id
   role_definition_name = "Reader"
   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
 }

 resource "azurerm_role_assignment" "ra2" {
   scope                = azurerm_virtual_network.vnet_aks.id
   role_definition_name = "Network Contributor"
   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
 }

 resource "azurerm_role_assignment" "ra3" {
   scope                = azurerm_application_gateway.appgw.id
   role_definition_name = "Contributor"
   principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
 }
resource "azurerm_kubernetes_cluster" "mycluster" {
  name                      = "${var.aks_name}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = "dev-aks"
  kubernetes_version        = var.aks_version
  oidc_issuer_enabled       = true
  private_cluster_enabled   = true
  private_dns_zone_id       = azurerm_private_dns_zone.dns_zones["aks_dns_zone"].id

  sku_tier = "Free"


identity {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.controlplane.id]
}


kubelet_identity {
  client_id                 = azurerm_user_assigned_identity.kubelet.client_id
  object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
  user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
}

key_vault_secrets_provider {
    secret_rotation_enabled = true
    
}

 network_profile {
  network_plugin     = "azure" # Azure CNI
  service_cidr       = "10.1.4.0/22"
  dns_service_ip     = "10.1.4.10"
}


ingress_application_gateway {
  gateway_id = azurerm_application_gateway.appgw.id
}

  default_node_pool {
    name                 = "newpool"
    vm_size              = "Standard_D2_v2"
    vnet_subnet_id       = azurerm_subnet.aks.id
    node_count           = 2
  }


   depends_on = [
     azurerm_application_gateway.appgw
   ]

  tags = var.tags
}

