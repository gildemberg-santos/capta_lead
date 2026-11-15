# Deploy — CaptaLead

Guia de implantação do CaptaLead em ambiente de produção.

---

## 📋 Pré-requisitos de Produção

| Item | Recomendação |
|------|-------------|
| Ruby | 3.4+ |
| Rails | 7.1+ |
| PostgreSQL | 16+ (com extensão jsonb) |
| Redis | 7+ |
| Ollama | 0.35+ (com modelo `tev1:4b`) |
| Sidekiq | 7+ |
| Nginx/Apache | Reverse proxy com SSL |
| Memória | Mínimo 4 GB RAM (Ollama tev1:4b usa ~4,6 GB) |
| GPU | Opcional (acelera inferência, não obrigatório) |

---

## 🏗️ Arquitetura de Produção

```
┌─────────────────┐      ┌──────────────────┐
│   Usuários      │      │  Time Comercial  │
└─────────┬───────┘      └────────┬─────────┘
          │                       │
          ▼                       ▼
┌─────────────────────────────────────────────┐
│              Nginx (SSL)                    │
│         (Reverse Proxy)                     │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│         Rails (Puma)                        │
│   puerto 3000                               │
└───────────────┬─────────────────────────────┘
                │
    ┌───────────┴───────────┐
    │                       │
    ▼                       ▼
┌─────────────┐   ┌─────────────────┐
│ PostgreSQL  │   │   Redis         │
│ (Dados)     │   │   (Sidekiq)     │
└─────────────┘   └─────────────────┘
                  │
                  ▼
           ┌─────────────┐
           │ Sidekiq     │
           │ Worker      │
           └──────┬──────┘
                  │
                  ▼
           ┌─────────────┐
           │ Ollama      │
           │ (Local)     │
           │ puerto 11434│
           └─────────────┘
```

---

## 🔧 Variáveis de Ambiente de Produção

Crie o arquivo `.env` de produção:

```bash
# Banco de dados
DATABASE_HOST=seu-banco-producao
DATABASE_PORT=5432
CAPTA_LEAD_DATABASE_PASSWORD=senha_forte_aqui

# Redis
REDIS_URL=redis://seu-redis:6379/0

# Ollama (deve ser acessível pelos workers)
OLLAMA_URL=http://ollama-host:11434
OLLAMA_TIMEOUT=120
QUALIFICATION_MODEL=tev1:4b

# Rails
RAILS_ENV=production
RAILS_MAX_THREADS=5
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Segurança
SECRET_KEY_BASE=chave_gerada_pelo_rails
```

**Gerar SECRET_KEY_BASE:**
```bash
bundle exec rails secret
```

**Sobre o banco em produção:** `config/database.yml` usa o usuário `capta_lead` e o banco `capta_lead_production` fixos, e lê a senha de `CAPTA_LEAD_DATABASE_PASSWORD`. As variáveis `DATABASE_USERNAME` e `DATABASE_NAME` não são lidas nesse ambiente.

---

## 🐳 Docker Compose de Produção

Exemplo de `docker-compose.prod.yml`:

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: capta_lead
      POSTGRES_PASSWORD: ${CAPTA_LEAD_DATABASE_PASSWORD}
      POSTGRES_DB: capta_lead_production
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  ollama:
    image: ollama/ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  web:
    build: .
    environment:
      DATABASE_HOST: db
      CAPTA_LEAD_DATABASE_PASSWORD: ${CAPTA_LEAD_DATABASE_PASSWORD}
      REDIS_URL: redis://redis:6379/0
      OLLAMA_URL: http://ollama:11434
      RAILS_ENV: production
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    depends_on:
      - db
      - redis
      - ollama

  sidekiq:
    build: .
    environment:
      DATABASE_HOST: db
      CAPTA_LEAD_DATABASE_PASSWORD: ${CAPTA_LEAD_DATABASE_PASSWORD}
      REDIS_URL: redis://redis:6379/0
      OLLAMA_URL: http://ollama:11434
      RAILS_ENV: production
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    depends_on:
      - db
      - redis
      - ollama
    command: bundle exec sidekiq -q low -q default

volumes:
  postgres_data:
  ollama_data:
```

---

## 🚀 Passos de Deploy

### 1. Preparar o servidor

```bash
# Instalar dependências do sistema
sudo apt-get update
sudo apt-get install -y build-essential libpq-dev postgresql-client

# Instalar Ruby 3.4 (via rbenv/asdf/rvm)
# Instalar Node.js e Yarn (se necessário para assets)
```

### 2. Clonar o repositório

```bash
git clone https://github.com/gildemberg-santos/capta_lead.git
cd capta_lead
```

### 3. Configurar variáveis de ambiente

```bash
cp .env.example .env.production
# Editar .env.production com valores reais
```

### 4. Instalar gems

```bash
bundle install --deployment --without development test
```

### 5. Banco de dados

```bash
RAILS_ENV=production bundle exec rails db:create db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

### 6. Pré-compilar assets

```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

### 7. Iniciar serviços

```bash
# Usando systemd ou Docker Compose
docker compose -f docker-compose.prod.yml up -d

# Ou iniciar manualmente
bundle exec puma -e production -b tcp://0.0.0.0:3000
bundle exec sidekiq -e production -q low -q default
```

### 8. Baixar modelo Tev1 no Ollama

```bash
ollama pull tev1:4b
```

### 9. Configurar Nginx (SSL)

Exemplo de configuração Nginx:

```nginx
server {
    listen 443 ssl;
    server_name seu-dominio.com;

    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## ⚠️ Cuidados de Produção

### 1. Ollama acessível pelos workers
O Sidekiq roda em processo separado. O Ollama deve ser acessível de ambos (web e sidekiq). Em Docker, use `http://ollama:11434`; em servidor direto, `http://localhost:11434`.

### 2. Digest do modelo
A tag `tev1:4b` pode apontar para outro arquivo após um `ollama pull`. Registre também o digest do modelo para reprodutibilidade.

### 3. Teste de carga
Modelo local não é gratuito (memória, CPU/GPU). Meça latência, memória e concorrência antes de dimensionar.

### 4. Limite de tamanho
Critérios com até 1.000 caracteres e respostas curtas (contexto do Tev1 ≈ 2.000 tokens).

### 5. Retenção de snapshots
Eles são dados do lead. Defina por quanto tempo guardar e crie job de limpeza.

### 6. Remoção da feature flag
Toda flag temporária precisa de data para sair do código.

### 7. Grupo de controle
Se o time só atende quem o modelo marcou, esses leads convertem mais e o modelo parece melhor do que é. Deixe uma parte sem ver a classificação.

---

## 📊 Monitoramento

- Logs do Sidekiq: `log/sidekiq.log`
- Logs do Rails: `log/production.log`
- Métricas do classificador: `bundle exec rails qualification:metrics`
- Health check: `GET /up` (retorna 200 se o app está vivo)

---

## 🔄 Atualização do Modelo

```bash
# Baixar nova versão
ollama pull tev1:4b

# Registrar o novo digest
ollama show tev1:4b --modelfile

# Reiniciar Sidekiq para usar o novo modelo (se necessário)
systemctl restart capta_lead-sidekiq
```

---

## 🔒 Segurança

- **SSL/TLS**: Obrigatório em produção
- **SECRET_KEY_BASE**: Nunca commitar no repositório
- **Senhas do banco**: Usar variáveis de ambiente
- **Access ao Ollama**: Restringir por firewall (apenas servidores da aplicação)
- **Backup**: Backup regular do PostgreSQL (contém dados dos leads)