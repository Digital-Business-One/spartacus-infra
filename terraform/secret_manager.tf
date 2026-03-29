resource "google_secret_manager_secret" "sendgrid_api_key" {
  project   = var.project_id
  secret_id = "SENDGRID_API_KEY"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Versão do secret gerenciada manualmente:
#   echo -n "SG.suachave" | gcloud secrets versions add SENDGRID_API_KEY \
#     --project=spartacus-artes-marciais --data-file=-
