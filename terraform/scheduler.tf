# ─── Cloud Scheduler: compute-absences (RFC-11) ─────────────────────────────
# Executa diariamente às 23:59 (America/Cuiaba) para computar faltas.
# Alunos sem check-in em aulas encerradas do dia recebem status "absent".

resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "spartacus-scheduler"
  display_name = "Spartacus Cloud Scheduler SA"
  depends_on   = [google_project_service.apis]
}

# Scheduler SA precisa invocar o Cloud Run
resource "google_cloud_run_v2_service_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_scheduler_job" "compute_absences" {
  project     = var.project_id
  name        = "compute-absences"
  description = "RFC-11: Computa faltas para aulas encerradas sem check-in"
  region      = var.region
  schedule    = "59 23 * * *"
  time_zone   = "America/Cuiaba"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.backend.uri}/jobs/compute-absences"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
      audience              = google_cloud_run_v2_service.backend.uri
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "10s"
    max_backoff_duration = "300s"
  }

  depends_on = [google_project_service.apis]
}
