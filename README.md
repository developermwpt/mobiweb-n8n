# n8n – Mobiweb (Docker / Hetzner)

Este repositório contém a configuração Docker para o servidor **n8n** da Mobiweb, alojado num VPS **Hetzner** ().

---

## 🚀 Deploy / Actualizar versão

O deploy é manual via SSH ao servidor. Para actualizar a versão do n8n:

1. Editar a primeira linha do  com a versão pretendida:

```dockerfile
# Exemplo: fixar versão
FROM n8nio/n8n:2.15.1
```

2. Fazer push para `main` (registo de histórico):

```bash
git commit -am chore: bump n8n to 2.15.1
git push origin main
```

3. No servidor, fazer rebuild e redeploy:

```bash
ssh -i ~/.ssh/github_actions_deploy root@178.104.42.14
cd /opt/mobiweb-n8n
git pull
docker compose build --no-cache
docker compose up -d
```

---

## ⚙️ Configuração do servidor (docker-compose.yml)

O ficheiro `docker-compose.yml` está no **.gitignore** propositadamente — contém credenciais sensíveis (password postgres, encryption key). Vive **apenas no servidor** em `/opt/mobiweb-n8n/docker-compose.yml`.

### Variáveis de ambiente activas (em produção)

| Variável | Valor | Descrição |
|---|---|---|
| `DB_TYPE` | `postgresdb` | Base de dados PostgreSQL 17 |
| `N8N_ENCRYPTION_KEY` | *(ver gestor de passwords)* | Chave de cifra das credenciais n8n |
| `GENERIC_TIMEZONE` | `Europe/Lisbon` | Fuso horário |
| `WEBHOOK_URL` | `https://n8n.mobiweb.pt/` | URL pública dos webhooks |
| `N8N_TRUST_PROXY` | `true` | Activar confiança no reverse proxy |
| `N8N_PROXY_HOPS` | `1` | Número de hops do proxy (evita ERR_ERL_UNEXPECTED_X_FORWARDED_FOR) |
| `N8N_TASK_RUNNERS_ENABLED` | `true` | Task runners activos (Python incluído) |
| `EXECUTIONS_TIMEOUT` | `600` | Timeout de execução de workflow (segundos) |
| `EXECUTIONS_TIMEOUT_MAX` | `3600` | Timeout máximo permitido (segundos) |
| `N8N_DEFAULT_HTTP_REQUEST_TIMEOUT` | `600000` | Timeout HTTP para nós externos, ex. OpenAI (ms) |

---

## 🔁 Migração para novo servidor

Se precisares de migrar o n8n para outro servidor, segue esta ordem **exacta**:

### 1. Exportar dados do servidor actual

```bash
# Exportar workflows
docker exec mobiweb-n8n-n8n-1 n8n export:workflow --all --output=/tmp/workflows.json
docker cp mobiweb-n8n-n8n-1:/tmp/workflows.json ./backup-workflows.json

# Exportar credenciais (cifradas — precisas da encryption key para as usar)
docker exec mobiweb-n8n-n8n-1 n8n export:credentials --all --output=/tmp/credentials.json
docker cp mobiweb-n8n-n8n-1:/tmp/credentials.json ./backup-credentials.json

# Backup do volume postgres (mais completo)
docker exec mobiweb-n8n-postgres-1 pg_dump -U n8n n8n > backup-postgres.sql
```

### 2. Guardar a N8N_ENCRYPTION_KEY

⚠️ **CRÍTICO.** A `N8N_ENCRYPTION_KEY` do docker-compose actual é a chave que cifra todas as credenciais guardadas no n8n (API keys, passwords, tokens). Sem ela, as credenciais exportadas são **irrecuperáveis**.

- Antes de migrar, confirmar o valor actual no servidor: `grep N8N_ENCRYPTION_KEY /opt/mobiweb-n8n/docker-compose.yml`
- Guardar num gestor de passwords (ex. 1Password / Bitwarden)
- Usar **exactamente o mesmo valor** no novo servidor

### 3. Preparar o novo servidor

```bash
# Clonar o repo
git clone https://github.com/developermwpt/mobiweb-n8n /opt/mobiweb-n8n
cd /opt/mobiweb-n8n

# Criar o docker-compose.yml com todas as variáveis (ver tabela acima)
# Garantir que N8N_ENCRYPTION_KEY é o mesmo valor do servidor anterior
nano docker-compose.yml

# Build e arranque
docker compose build
docker compose up -d
```

### 4. Importar dados

```bash
# Copiar backups para o novo servidor e importar
docker cp backup-workflows.json mobiweb-n8n-n8n-1:/tmp/
docker exec mobiweb-n8n-n8n-1 n8n import:workflow --input=/tmp/backup-workflows.json

docker cp backup-credentials.json mobiweb-n8n-n8n-1:/tmp/
docker exec mobiweb-n8n-n8n-1 n8n import:credentials --input=/tmp/backup-credentials.json
```

### 5. Validar

- Aceder a `https://n8n.mobiweb.pt` e confirmar que os workflows estão presentes
- Testar um workflow com credenciais externas (confirma que a encryption key está correcta)
- Verificar logs: `docker logs mobiweb-n8n-n8n-1 --tail=50`

---

## ⚠️ Notas operacionais

- O `docker-compose.yml` **não está no git**. Qualquer alteração feita directamente no servidor (variáveis, portas, etc.) deve ser documentada aqui no README.
- Se o servidor for recriado sem backup do `docker-compose.yml`, perdem-se todas as variáveis de ambiente — incluindo a `N8N_ENCRYPTION_KEY`.
- O postgres corre no mesmo compose (`mobiweb-n8n-postgres-1`). Não fazer `docker compose down -v` — apaga os volumes e perde-se a base de dados.

---

## Version History

- Bump n8n version 10/02/2025
- Bump n8n version 15/08/2025
- Bump n8n version 15/12/2025
- Bump n8n version 29/12/2025
- Bump n8n version 19/01/2026
- Bump n8n version 21/01/2026
- Bump n8n version 26/01/2026
- Bump n8n version 31/01/2026
- Bump n8n version 03/02/2026
- Bump n8n version 09/02/2026
- Bump n8n version 13/02/2026
- Bump n8n version 16/02/2026
- Bump n8n version 18/02/2026
- Bump n8n version 19/02/2026
- Bump n8n version 24/02/2026
- Bump n8n version 26/02/2026
- Bump n8n version 04/03/2026
- Bump n8n version 05/03/2026
- Bump n8n version 10/03/2026
- Bump n8n version 13/03/2026
- Bump n8n version 16/03/2026
- Bump n8n version 20/03/2026
- Bump n8n version 25/03/2026
- Bump n8n version 26/03/2026
- Bump n8n version 27/03/2026
- Bump n8n version 31/03/2026
- Bump n8n version 13/04/2026
- Bump n8n version 14/04/2026
- Migração Heroku → Hetzner / Documentação operacional 24/04/2026
