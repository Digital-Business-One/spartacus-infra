# ── Cloud Function: send-email ────────────────────────────────────────────────
#
# Triggered by PubSub topic email-notifications.
# Sends emails via SendGrid Dynamic Templates.
#
# The function source is deployed via CI/CD from:
#   repos/backend/functions/send_email/
#
# This resource provisions the infrastructure (trigger, IAM, secret binding).
# The actual function code is deployed separately via gcloud CLI in CI.

resource "google_service_account" "send_email_fn" {
  project      = var.project_id
  account_id   = "fn-send-email"
  display_name = "Cloud Function — send-email"
}

# Allow the function SA to read the SendGrid secret
resource "google_secret_manager_secret_iam_member" "fn_sendgrid_secret" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.sendgrid_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.send_email_fn.email}"
}

# Allow the function SA to receive Eventarc events
resource "google_project_iam_member" "fn_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.send_email_fn.email}"
}
