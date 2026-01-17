# Workload Module: Event Grid
# Creates an Event Grid Topic with subscriptions
# NOTE: Uses direct attributes for endpoint IDs, NOT dynamic blocks (Provider 4.x requirement)

resource "azurerm_eventgrid_topic" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  input_schema                  = var.input_schema
  public_network_access_enabled = var.public_network_access_enabled

  # Identity
  identity {
    type         = var.managed_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.managed_identity_id != null ? [var.managed_identity_id] : []
  }

  tags = var.tags
}

# Event Subscriptions for webhooks
resource "azurerm_eventgrid_event_subscription" "webhook" {
  for_each = { for k, v in var.subscriptions : k => v if v.endpoint_type == "webhook" }

  name  = each.key
  scope = azurerm_eventgrid_topic.main.id

  webhook_endpoint {
    url = each.value.endpoint_url
  }

  included_event_types  = each.value.event_types
  event_delivery_schema = each.value.event_delivery_schema

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      max_delivery_attempts = retry_policy.value.max_delivery_attempts
      event_time_to_live    = retry_policy.value.event_time_to_live
    }
  }

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
    }
  }
}

# Event Subscriptions for Service Bus Queue - Direct attribute (NOT dynamic block)
resource "azurerm_eventgrid_event_subscription" "service_bus_queue" {
  for_each = { for k, v in var.subscriptions : k => v if v.endpoint_type == "service_bus_queue" }

  name  = each.key
  scope = azurerm_eventgrid_topic.main.id

  # CORRECT: Direct attribute, NOT dynamic block
  service_bus_queue_endpoint_id = each.value.service_bus_queue_id

  included_event_types  = each.value.event_types
  event_delivery_schema = each.value.event_delivery_schema

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      max_delivery_attempts = retry_policy.value.max_delivery_attempts
      event_time_to_live    = retry_policy.value.event_time_to_live
    }
  }

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
    }
  }
}

# Event Subscriptions for Service Bus Topic - Direct attribute (NOT dynamic block)
resource "azurerm_eventgrid_event_subscription" "service_bus_topic" {
  for_each = { for k, v in var.subscriptions : k => v if v.endpoint_type == "service_bus_topic" }

  name  = each.key
  scope = azurerm_eventgrid_topic.main.id

  # CORRECT: Direct attribute, NOT dynamic block
  service_bus_topic_endpoint_id = each.value.service_bus_topic_id

  included_event_types  = each.value.event_types
  event_delivery_schema = each.value.event_delivery_schema

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      max_delivery_attempts = retry_policy.value.max_delivery_attempts
      event_time_to_live    = retry_policy.value.event_time_to_live
    }
  }

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
    }
  }
}

# Event Subscriptions for Storage Queue
resource "azurerm_eventgrid_event_subscription" "storage_queue" {
  for_each = { for k, v in var.subscriptions : k => v if v.endpoint_type == "storage_queue" }

  name  = each.key
  scope = azurerm_eventgrid_topic.main.id

  storage_queue_endpoint {
    storage_account_id = each.value.storage_account_id
    queue_name         = each.value.storage_queue_name
  }

  included_event_types  = each.value.event_types
  event_delivery_schema = each.value.event_delivery_schema

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      max_delivery_attempts = retry_policy.value.max_delivery_attempts
      event_time_to_live    = retry_policy.value.event_time_to_live
    }
  }

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
    }
  }
}

# RBAC assignment for managed identity
resource "azurerm_role_assignment" "eventgrid_data_sender" {
  count = var.managed_identity_principal_id != null ? 1 : 0

  scope                = azurerm_eventgrid_topic.main.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = var.managed_identity_principal_id
}
