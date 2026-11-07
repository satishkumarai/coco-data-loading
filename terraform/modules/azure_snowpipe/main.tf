terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 1. Azure Storage Queue for Snowpipe Event Ingestion
resource "azurerm_storage_queue" "snowpipe_queue" {
  name                 = "${var.pipeline_name}-snowpipe-queue"
  storage_account_name = var.storage_account_name
}

# 2. Azure Event Grid System Topic for Storage Account
resource "azurerm_eventgrid_system_topic" "storage_topic" {
  name                   = "${var.pipeline_name}-eg-topic"
  resource_group_name    = var.resource_group_name
  location               = var.location
  source_arm_resource_id = var.storage_account_id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

# 3. Event Grid Subscription routing BlobCreated events to Storage Queue
resource "azurerm_eventgrid_system_topic_event_subscription" "queue_sub" {
  name                = "${var.pipeline_name}-blob-created-sub"
  system_topic        = azurerm_eventgrid_system_topic.storage_topic.name
  resource_group_name = var.resource_group_name

  storage_queue_endpoint {
    storage_account_id = var.storage_account_id
    queue_name         = azurerm_storage_queue.snowpipe_queue.name
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.container_name}/blobs/${var.blob_prefix}"
  }

  event_delivery_schema = "EventGridEvent"
}
