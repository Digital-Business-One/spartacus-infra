resource "google_firebase_project" "spartacus" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_firestore_database" "default" {
  provider = google-beta
  project  = var.project_id

  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_firebase_project.spartacus]
}

# ─── Firebase Auth (Identity Toolkit) ─────────────────────────────────────────
# Habilita o Firebase Auth via Identity Platform.
# IMPORTANTE: declarar email{} aqui para que o Terraform não desabilite
# o provider ao aplicar o bloco sign_in.
# O Google Sign-In como provider OAuth é ativado no Firebase Console
# (Authentication → Sign-in method → Google) — operação única, não requer Terraform.
resource "google_identity_platform_config" "auth" {
  provider = google-beta
  project  = var.project_id

  sign_in {
    allow_duplicate_emails = false

    email {
      enabled           = true
      password_required = true
    }
  }

  depends_on = [
    google_firebase_project.spartacus,
    google_project_service.apis,
  ]
}

# ─── Firebase Storage ──────────────────────────────────────────────────────────
# The default bucket was created by Firebase Console as
# {project_id}.firebasestorage.app. Import it into Terraform state with:
#   terraform import google_storage_bucket.firebase_storage spartacus-artes-marciais.firebasestorage.app
#   terraform import google_firebase_storage_bucket.default projects/spartacus-artes-marciais/buckets/spartacus-artes-marciais.firebasestorage.app

resource "google_storage_bucket" "firebase_storage" {
  project                     = var.project_id
  name                        = "${var.project_id}.firebasestorage.app"
  location                    = var.region
  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebase_storage_bucket" "default" {
  provider  = google-beta
  project   = var.project_id
  bucket_id = google_storage_bucket.firebase_storage.name
}

# ─── Firebase Hosting ──────────────────────────────────────────────────────────
resource "google_firebase_hosting_site" "backoffice" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.project_id

  depends_on = [google_firebase_project.spartacus]
}
