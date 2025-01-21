data "azurerm_resource_group" "rg" {
  name = "testrg"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "test-api-cluster"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_user_assigned_identity" "workload_identity" {
  name                = "id-uami-workloadidentity"
  resource_group_name = data.azurerm_resource_group.rg.name
}