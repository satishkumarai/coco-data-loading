variable "pipeline_name" {
  type        = string
  description = "Logical identifier for the Azure Snowpipe pipeline"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region (e.g., East US)"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the ADLS Gen2 / Blob Storage Account"
}

variable "storage_account_id" {
  type        = string
  description = "ARM Resource ID of the Storage Account"
}

variable "container_name" {
  type        = string
  description = "Target storage container name"
}

variable "blob_prefix" {
  type        = string
  description = "Prefix within container to filter BlobCreated events"
  default     = "raw/orders/"
}
