output "managed_user_client_id" {
  value = azurerm_user_assigned_identity.workload_identity.client_id
}

output "kubernetes_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.mycluster.oidc_issuer_url
}