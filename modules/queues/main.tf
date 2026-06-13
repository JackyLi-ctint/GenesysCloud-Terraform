terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_routing_queue" "queues" {
  for_each                 = toset(var.queue_names)
  name                     = each.value
  description              = "${each.value} queue"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = var.acw_timeout_ms
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true

  dynamic "members" {
    for_each = var.queue_members
    content {
      user_id  = members.value
      ring_num = 1
    }
  }
}

output "queue_ids" {
  description = "Map of queue names to queue IDs."
  value       = { for name, queue in genesyscloud_routing_queue.queues : name => queue.id }
}
