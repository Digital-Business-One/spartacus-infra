variable "project_id" {
  type        = string
  description = "ID do projeto GCP"
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "Região padrão GCP (Carolina do Sul)"
}

variable "github_org" {
  type        = string
  description = "Organização GitHub (ex: Digital-Business-One)"
}

variable "cors_origins" {
  type        = string
  default     = "https://backoffice.spartacus.app.br,https://spartacus.app.br,https://app.spartacus.app.br,https://spartacus-artes-marciais-app.web.app"
  description = "Origens CORS permitidas pelo backend (separadas por vírgula)"
}
