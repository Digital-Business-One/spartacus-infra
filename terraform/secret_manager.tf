resource "google_secret_manager_secret" "mailersend_api_key" {
  project   = var.project_id
  secret_id = "MAILERSEND_API_KEY"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Versão do secret gerenciada manualmente (gcloud ou Firebase Extension).
# Terraform apenas cria o secret container, não gerencia o valor.
#
# Para definir o valor:
#   echo -n "mlsn.suachave" | gcloud secrets versions add MAILERSEND_API_KEY \
#     --project=spartacus-artes-marciais --data-file=-
