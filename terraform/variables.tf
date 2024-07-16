variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "resources01"
}

variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "France Central"
}

variable "staging_account_name" {
  description = "The name of the staging storage account"
  type        = string
  default     = "staging01xyz123"
}

variable "datalake_account_name" {
  description = "The name of the data lake storage account"
  type        = string
  default     = "datalake01xyz123"
}

variable "filesystem_name" {
  description = "The name of the data lake filesystem"
  type        = string
  default     = "filesystem01xyz123"
}

variable "synapse_workspace_name" {
  description = "The name of the Synapse workspace"
  type        = string
  default     = "synapseworkspace01xyz123"
}

variable "synapse_admin_login" {
  description = "The admin login for the Synapse workspace"
  type        = string
  default     = "synapseadmin"
}

variable "synapse_admin_password" {
  description = "The admin password for the Synapse workspace"
  type        = string
  default     = "P@ssw0rd1234"
  sensitive   = true
}

variable "sql_pool_name" {
  description = "The name of the Synapse SQL pool"
  type        = string
  default     = "sqlpool01xyz123"
}

variable "start_ip_address" {
  description = "The start IP address for the Synapse firewall rule"
  type        = string
  default     = "0.0.0.0"
}

variable "end_ip_address" {
  description = "The end IP address for the Synapse firewall rule"
  type        = string
  default     = "255.255.255.255"
}

variable "powerbi_name" {
  description = "The name of the Power BI Embedded instance"
  type        = string
  default     = "examplepowerbi"
}

variable "powerbi_sku" {
  description = "The SKU for the Power BI Embedded instance"
  type        = string
  default     = "A1"
}

variable "powerbi_admins" {
  description = "The list of administrators for the Power BI Embedded instance"
  type        = list(string)
  default     = ["azsdktest@microsoft.com"]
}

variable "vm_admin_username" {
  description = "The admin username for the VM"
  type        = string
}

variable "vm_admin_password" {
  description = "The admin password for the VM"
  type        = string
  sensitive   = true
}