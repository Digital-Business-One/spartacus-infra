# spartacus-infra

Infra compartilhada do projeto Spartacus: Docker Compose para dev local
(Firebase Emulator Suite + backend FastAPI) e Terraform para provisionar
GCP.

## Dev local

### Pré-requisitos

- Docker + Docker Compose
- Os outros repos clonados como siblings de `spartacus-infra/`:
  `spartacus-backend/`, `spartacus-app/`, `spartacus-backoffice/`.
  O `docker-compose.yml` monta `../backend` e `../backend/functions/*`
  como volumes — sem esses paths ele não sobe.

### Configurar `.env` — onde colocar cada variável

Cada variável precisa ficar no `.env` do repo que **de fato lê aquela
variável em runtime**. Docker Compose só injeta variáveis nos containers
que ele gerencia; serviços rodando fora do Compose (ex.: backend
`uv run uvicorn` standalone) leem do seu próprio `.env`.

Tem dois `.env` em jogo:

- **`repos/infra/.env`** — lido pelo Docker Compose, injetado nos
  containers `emulators` e `backend` definidos no `docker-compose.yml`
- **`repos/backend/.env`** — lido pelo processo Python do backend via
  `load_dotenv()` quando ele roda fora do Compose (`uv run uvicorn` direto)

Crie os dois a partir dos templates:

```bash
cp repos/infra/.env.example    repos/infra/.env
cp repos/backend/.env.example  repos/backend/.env
```

Variáveis e onde cada uma pertence:

| Variável | Quem lê | Arquivo | Descrição |
|---|---|---|---|
| `FIREBASE_PROJECT_ID` | container `emulators`, container `backend` | `infra/.env` | ID do projeto Firebase/GCP |
| `ROOT_PROJECT_ID` | backend | `infra/.env` + `backend/.env` | ID do projeto ROOT no Firestore (multi-tenant) |
| `SENDGRID_API_KEY` | Cloud Function `send_email` (dentro do container `emulators`) | `infra/.env` | Com key, envia e-mails de verdade em local. Sem, loga conteúdo no console com prefixo `[LOCAL EMAIL]`. Gere em https://app.sendgrid.com/settings/api_keys |
| `APP_WEB_URL` | backend | `infra/.env` + `backend/.env` | Base URL do Expo web app. Usada pelo backend para montar o link de reset de senha (`/reset-password?oobCode=...`) na página com branding Spartacus. Default: `http://localhost:8081` |
| `CORS_ORIGINS` | backend | `backend/.env` | Origens aceitas pelo CORS (dev servers do app + backoffice) |

**Regra prática**: se você sobe o stack inteiro via `docker-compose up`,
basta `infra/.env`. Se você sobe o backend manualmente (uvicorn direto)
e só os emuladores em container, as variáveis consumidas pelo backend
(`APP_WEB_URL`, `CORS_ORIGINS`, `ROOT_PROJECT_ID`) precisam estar em
`backend/.env`.

**Ordem de precedência** dentro de cada processo:

1. Variável no shell (`export FOO=...`)
2. `.env` do diretório onde o processo roda
3. Default hardcoded no código ou no compose

Os dois `.env` estão no `.gitignore` — segredos nunca vão pro repo. Os
`.env.example` são os templates versionados.

### Subir o stack

```bash
docker-compose up
```

Serviços expostos:

- **Firebase Emulator UI** — http://localhost:4000
- **Auth emulator** — localhost:9099
- **Firestore emulator** — localhost:8080
- **Storage emulator** — localhost:9199
- **Functions emulator** — localhost:5001
- **Backend FastAPI** — http://localhost:8000

Dados do emulador persistem em `emulator-data/` (gitignored).

### Aplicar mudanças

- **Backend** (`../backend/app/**`): o uvicorn sobe com `--reload`, pega
  mudanças automaticamente.
- **Cloud Functions** (`../backend/functions/**`): não hot-reloadam.
  Rode `docker-compose restart emulators` após mudar qualquer coisa
  em `orchestrator/`, `send_email/` ou `send_push/`.
- **`.env`**: `docker-compose restart backend` (ou `up` de novo).

## Terraform

Ver `terraform/` — provisiona APIs GCP, Artifact Registry, Cloud Run,
Workload Identity Federation, Service Accounts, Firebase Project e
Firestore.

Bucket de state: `gs://spartacus-artes-marciais-tfstate` (já criado).
