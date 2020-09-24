variable "public_key" {}
variable "server_count_azure" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "destination_port_ranges" {
  type = list(string)
}