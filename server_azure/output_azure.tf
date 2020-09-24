output "public_ip_azure" {
  value = azurerm_public_ip.chavo-public-ip.*.ip_address
}