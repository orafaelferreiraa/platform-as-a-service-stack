# =============================================================================
# Event Grid Module (System Topic with Service Bus Queue destination)
# Uses direct endpoint attributes - NO dynamic blocks for endpoints
# =============================================================================

resource "azurerm_eventgrid_system_topic" "main" {
  name                   = var.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = var.source_arm_resource_id
  topic_type             = var.topic_type
  tags                   = var.tags
}

# Event Subscription with Service Bus Queue endpoint (direct attribute)
resource "azurerm_eventgrid_system_topic_event_subscription" "service_bus_queue" {
  for_each = { for s in var.subscriptions : s.name => s if s.endpoint_type == "service_bus_queue" }

  name                = each.value.name
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = var.resource_group_name

  # Direct attribute - not dynamic block per PROMPT.md rules
  service_bus_queue_endpoint_id = each.value.endpoint_id

  included_event_types = each.value.included_event_types

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }

  dynamic "advanced_filter" {
    for_each = each.value.advanced_filters != null ? each.value.advanced_filters : []
    content {
      dynamic "string_contains" {
        for_each = advanced_filter.value.type == "string_contains" ? [advanced_filter.value] : []
        content {
          key    = string_contains.value.key
          values = string_contains.value.values
        }
      }
      dynamic "string_begins_with" {
        for_each = advanced_filter.value.type == "string_begins_with" ? [advanced_filter.value] : []
        content {
          key    = string_begins_with.value.key
          values = string_begins_with.value.values
        }
      }
      dynamic "string_ends_with" {
        for_each = advanced_filter.value.type == "string_ends_with" ? [advanced_filter.value] : []
        content {
          key    = string_ends_with.value.key
          values = string_ends_with.value.values
        }
      }
    }
  }
}

# Event Subscription with Service Bus Topic endpoint (direct attribute)
resource "azurerm_eventgrid_system_topic_event_subscription" "service_bus_topic" {
  for_each = { for s in var.subscriptions : s.name => s if s.endpoint_type == "service_bus_topic" }

  name                = each.value.name
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = var.resource_group_name

  # Direct attribute - not dynamic block
  service_bus_topic_endpoint_id = each.value.endpoint_id

  included_event_types = each.value.included_event_types

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }
}

# Event Subscription with Storage Queue endpoint (direct attribute)
resource "azurerm_eventgrid_system_topic_event_subscription" "storage_queue" {
  for_each = { for s in var.subscriptions : s.name => s if s.endpoint_type == "storage_queue" }

  name                = each.value.name
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = var.resource_group_name

  storage_queue_endpoint {
    storage_account_id = each.value.storage_account_id
    queue_name         = each.value.queue_name
  }

  included_event_types = each.value.included_event_types

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }
}

# Event Subscription with Webhook endpoint
resource "azurerm_eventgrid_system_topic_event_subscription" "webhook" {
  for_each = { for s in var.subscriptions : s.name => s if s.endpoint_type == "webhook" }

  name                = each.value.name
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = var.resource_group_name

  webhook_endpoint {
    url = each.value.webhook_url
  }

  included_event_types = each.value.included_event_types

  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }
}
