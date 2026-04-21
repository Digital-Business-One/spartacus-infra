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

# ─── Firestore Composite Indexes ──────────────────────────────────────────────
# Managed by Terraform so `terraform apply` keeps them in sync.
# Remove firestore.indexes.json — single source of truth is here.

# timeline_entries: projectId + createdAt DESC (unfiltered feed)
resource "google_firestore_index" "timeline_entries_project_created" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "timeline_entries"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}

# timeline_entries: projectId + type + createdAt DESC (filtered feed)
resource "google_firestore_index" "timeline_entries_project_type_created" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "timeline_entries"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "type"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}

# timeline_entries: projectId + targetUid + createdAt DESC (user feed)
resource "google_firestore_index" "timeline_entries_project_target_created" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "timeline_entries"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "targetUid"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}

# posts: projectId + createdAt DESC
resource "google_firestore_index" "posts_project_created" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "posts"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}

# posts: projectId + type + createdAt DESC
resource "google_firestore_index" "posts_project_type_created" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "posts"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "type"
    order      = "ASCENDING"
  }
  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }
}

# attendance: projectId + userId + aulaId
resource "google_firestore_index" "attendance_project_user_aula" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "attendance"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "userId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "aulaId"
    order      = "ASCENDING"
  }
}

# attendance: projectId + userId + status
resource "google_firestore_index" "attendance_project_user_status" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "attendance"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "userId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "status"
    order      = "ASCENDING"
  }
}

# attendance: projectId + aulaId + userId (dashboard RFC-14)
resource "google_firestore_index" "attendance_project_aula_user" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "attendance"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "aulaId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "userId"
    order      = "ASCENDING"
  }
}

# eventos_calendario: projectId + startDate
resource "google_firestore_index" "eventos_calendario_project_start" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = "eventos_calendario"

  fields {
    field_path = "projectId"
    order      = "ASCENDING"
  }
  fields {
    field_path = "startDate"
    order      = "ASCENDING"
  }
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

# Public read, authenticated write (via Cloud Run SA or Firebase Auth)
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.firebase_storage.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# ─── Firebase Hosting ──────────────────────────────────────────────────────────
resource "google_firebase_hosting_site" "backoffice" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.project_id

  depends_on = [google_firebase_project.spartacus]
}

resource "google_firebase_hosting_site" "app" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-app"

  depends_on = [google_firebase_project.spartacus]
}
