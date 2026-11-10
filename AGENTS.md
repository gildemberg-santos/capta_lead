# AGENTS.md — CaptaLead

Guia de operação para agentes do OpenCode trabalhando neste projeto.

---

## 📋 Visão Geral

**CaptaLead** é uma plataforma SaaS fictícia de captação de leads feita em Ruby on Rails 7.1 que usa um modelo de decisão local (Tev1 da Together AI, rodando no Ollama) para classificar leads como qualificados ou não.

Inclui: filtro de dados pessoais (LGPD), job assíncrono (Sidekiq), testes (RSpec), relatório de métricas (precisão, recall, acurácia, Brier score, calibração) e interface visual profissional (Bootstrap 5).

---

## 🗂️ Estrutura de Diretórios

```
capta_lead/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── companies_controller.rb      # CRUD empresas + critérios IA
│   │   ├── dashboard_controller.rb      # métricas, calibração, status Ollama
│   │   ├── lead_qualifications_controller.rb  # listagem/detalhe qualificações
│   │   └── leads_controller.rb          # CRUD leads + formulário dinâmico + qualificar
│   ├── helpers/
│   │   └── application_helper.rb        # lead_answer, criteria_value, preview_criteria
│   ├── javascript/
│   │   └── controllers/
│   │       └── lead_form_controller.js  # campos dinâmicos, modo Visual/JSON
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── company.rb                   # Flipper::Identifier, DEFAULT_CRITERIA, validação JSON
│   │   ├── lead.rb                      # validação form_fields, campos pessoais vs negócio
│   │   └── lead_qualification.rb        # enum status, snapshots jsonb
│   ├── services/qualification/
│   │   ├── answer_sanitizer.rb          # filtro de dados pessoais (tipos + regex LGPD)
│   │   ├── enqueuer.rb                  # feature flag, idempotência, enfileira job
│   │   ├── evaluator.rb                 # orquestra filtro → modelo → interpretação → upsert
│   │   ├── interpreter.rb               # nota → status + confiança
│   │   ├── metrics.rb                   # matriz de confusão, precisão, recall, brier, calibração
│   │   └── ollama_client.rb             # cliente /v1/systemone, TransientError/InvalidResponse
│   ├── validators/
│   │   └── jsonb_schema_validator.rb    # valida critérios JSON (chaves obrigatórias, threshold 0-1)
│   ├── views/
│   │   ├── companies/                   # index, new, edit, show, _criteria
│   │   ├── dashboard/                   # index (cards, métricas, calibração, Ollama)
│   │   ├── leads/                       # index, new, edit, show, _form_fields, _form_fields_field
│   │   ├── lead_qualifications/         # index, show
│   │   └── layouts/
│   │       └── application.html.erb     # layout com navbar, hero, footer
│   ├── sidekiq/
│   │   └── qualify_lead_job.rb          # fila low, retry 3, sidekiq_retries_exhausted
│   └── assets/
│       └── stylesheets/
│           └── capta_lead.css           # design system profissional
├── db/
│   ├── migrate/
│   │   ├── 20261110000000_create_companies.rb
│   │   ├── 20261110000001_create_leads.rb
│   │   ├── 20261110000002_create_lead_qualifications.rb
│   │   ├── 20261110000003_add_qualification_criteria_to_companies.rb
│   │   └── 20261110143334_create_flipper_tables.rb
│   ├── schema.rb
│   └── seeds.rb                         # 3 empresas, 11 leads, 9 qualificações
├── spec/
│   ├── factories/
│   │   ├── companies.rb
│   │   ├── leads.rb
│   │   └── lead_qualifications.rb
│   ├── services/qualification/
│   │   ├── answer_sanitizer_spec.rb
│   │   ├── ollama_client_spec.rb
│   │   ├── interpreter_spec.rb
│   │   ├── evaluator_spec.rb
│   │   ├── enqueuer_spec.rb
│   │   └── metrics_spec.rb
│   ├── spec_helper.rb
│   └── rails_helper.rb
├── lib/tasks/qualification.rake         # rake qualification:metrics
├── config/
│   ├── initializers/flipper.rb          # feature flag com ActiveRecord
│   ├── initializers/sidekiq.rb          # conexão Redis
│   └── database.yml                     # conexão PostgreSQL via ENV
├── Dockerfile
├── docker-compose.yml                   # postgres, redis, web, sidekiq
├── bin/
│   └── ollama_check                     # valida Ollama local + modelo tev1:4b
├── public/javascripts/
│   └── lead_form_controller.js          # JS de campos dinâmicos
├── docs/
│   ├── ARCHITECTURE.md                  # decisões de arquitetura
│   ├── DEPLOY.md                        # deploy em produção
│   └── LGPD.md                          # proteção de dados pessoais
├── app/services/qualification/README.md # documentação dos serviços de IA
├── spec/TESTING.md                      # convenções de teste
├── .env.example
├── Gemfile
├── README.md
└── AGENTS.md                            # este arquivo
```

---

## 🚀 Como Rodar a Aplicação

### Pré-requisitos

| Item | Versão | Notas |
|------|--------|-------|
| Ruby | 3.4+ | via asdf |
| Rails | 7.1+ | |
| PostgreSQL | 16+ | usa `jsonb` |
| Redis | 7+ | para Sidekiq |
| Ollama | 0.35+ | local, com modelo `tev1:4b` |

### Instalação

```bash
# 1. Entrar no projeto
cd /home/gildembergsantos/Documentos/capta_lead

# 2. Instalar gems
bundle install

# 3. Banco de dados
bundle exec rails db:create db:migrate
bundle exec rails db:seed

# 4. Verificar Ollama local
chmod +x bin/ollama_check
./bin/ollama_check

# 5. Subir banco e Redis (Docker)
docker compose up -d db redis

# 6. Rodar Rails
DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres REDIS_URL=redis://localhost:6379/0 bundle exec rails server -b 127.0.0.1 -p 3000

# 7. Em outro terminal, rodar Sidekiq
DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres REDIS_URL=redis://localhost:6379/0 bundle exec sidekiq -q low -q default
```

Acesse: **http://localhost:3000/**

---

## 🧪 Como Rodar Testes

```bash
cd /home/gildembergsantos/Documentos/capta_lead

# Suíte completa (28 exemplos, 0 falhas)
DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres REDIS_URL=redis://localhost:6379/0 bundle exec rspec

# Arquivo específico
DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres REDIS_URL=redis://localhost:6379/0 bundle exec rspec spec/services/qualification/evaluator_spec.rb

# Formato documentação
bundle exec rspec --format documentation
```

Os testes usam **WebMock** para simular chamadas ao Ollama — não é necessário ter o modelo rodando.

---

## 🗄️ Modelo de Dados

### Companies
- `name` (string, unique)
- `demo` (boolean, default: false)
- `qualification_criteria` (jsonb, default: `{}`)
- has_many :leads, has_many :lead_qualifications (through: leads)

### Leads
- `company` (belongs_to)
- `form_fields` (jsonb, default: `{}`) — array de {label, type, value}
- has_one :lead_qualification
- `demo?` delega para company.demo?

### LeadQualifications
- `lead` (belongs_to, index único)
- `status` (enum: pending, qualified, not_qualified, unclassified)
- `score` (decimal, 4,3)
- `confidence` (string: high/medium/low)
- `model_version` (string)
- `answers_snapshot` (jsonb)
- `criteria_snapshot` (jsonb)
- `error_message` (string)
- `outcome` (string: "won"/"lost", preenchido pelo time comercial)
- `evaluated_at` (datetime)

---

## 🤖 Serviços de Qualificação (app/services/qualification/)

| Serviço | Responsabilidade | Arquivo |
|---------|-----------------|---------|
| **AnswerSanitizer** | Remove/mascará dados pessoais (LGPD) por tipo de campo + regex em texto livre | `answer_sanitizer.rb` |
| **OllamaClient** | Chama API `/v1/systemone` do Tev1, valida resposta 0-1, distingue TransientError vs InvalidResponse | `ollama_client.rb` |
| **Interpreter** | Converte nota (probabilidade) em status + confiança por distância do limiar | `interpreter.rb` |
| **Evaluator** | Orquestra: sanitiza → chama modelo → interpreta → grava com upsert | `evaluator.rb` |
| **Enqueuer** | Feature flag (Flipper), idempotência, cria qualificação pendente + enfileira job | `enqueuer.rb` |
| **Metrics** | Matriz de confusão, acurácia, precisão, recall, Brier score, calibração por faixa | `metrics.rb` |

### Fluxo de Qualificação

```
Lead criado → Enqueuer.call(lead) → 
  Verifica demo? → Verifica Flipper.enabled? → Verifica idempotência → 
  Cria LeadQualification(status: pending) → QualifyLeadJob.perform_async → 
  Evaluator.new(lead).call → 
    AnswerSanitizer.call(form_fields) → 
    OllamaClient.call(answers, criteria) → 
    Interpreter.call(probability, threshold) → 
    LeadQualification.upsert(...)
```

---

## 🔄 Job Sidekiq

**Arquivo:** `app/sidekiq/qualify_lead_job.rb`

- Fila: `low`
- Retry: 3
- `sidekiq_retries_exhausted`: marca lead como `unclassified` com erro "serviço de inferência indisponível"
- Connexão Redis via `REDIS_URL` env var

---

## 🔧 Tarefas Rake

```bash
# Relatório de métricas comparadas com outcome comercial
bundle exec rails qualification:metrics
```

Saída exemplo:
```ruby
{ matriz: { vp: 26, fp: 83, fn: 8, vn: 183 },
  acuracia: 0.697, precisao: 0.239, recall: 0.765, brier: 0.217,
  calibracao: [...] }
```

---

## 🔑 Flipper (Feature Flags)

**Arquivo:** `config/initializers/flipper.rb`

- Adapter: ActiveRecord
- Ativar para uma empresa:
  ```ruby
  Flipper.enable_actor(:lead_qualification, Company.find_by!(name: "Contábil Norte"))
  ```
- Verificar:
  ```ruby
  Flipper.enabled?(:lead_qualification, company)
  ```

---

## 🔒 LGPD e Segurança

### Sanitização de Dados Pessoais (`AnswerSanitizer`)

**Duas camadas:**
1. **Por tipo de campo**: remove campos com tipo `name`, `email`, `phone`, `whatsapp`, `cpf`, `cnpj`, `address`, `password`
2. **Por padrão em texto livre**: máscara de email, CNPJ, CPF, phone em campos textarea

**Regras importantes:**
- CNPJ vem antes de CPF na ordem de máscara (para não cortar pelo meio)
- Regex não pega tudo — tratar como redução de risco, não garantia
- Dados sanitizados vão para o modelo; dados originais ficam no `form_fields` do lead

### Injeção de Prompt

- Dados do lead vão em `state`, pergunta/critérios vão em `questions` — separação é primeira defesa
- Nunca montar prompt manualmente com texto do lead
- Validar intervalo 0-1 no Ruby (não confiar no modelo)

---

## 🌍 Variáveis de Ambiente

Cópie `.env.example` para `.env`:

```
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
REDIS_URL=redis://localhost:6379/0
OLLAMA_URL=http://localhost:11434
QUALIFICATION_MODEL=tev1:4b
RAILS_MAX_THREADS=5
RAILS_ENV=development
```

---

## 🐳 Docker Compose

Sobe apenas **PostgreSQL** e **Redis** (Ollama é local):

```bash
docker compose up -d db redis
```

O Ollama deve estar rodando na máquina host na porta 11434.

---

## 🧪 Adicionando Nova Funcionalidade (Fluxo Recomendado)

### 1. Explorar código existente
```bash
# Entender a camada de serviços
cat app/services/qualification/evaluator.rb
```

### 2. Criar novo serviço (exemplo: exportador)
```ruby
# app/services/qualification/exporter.rb
module Qualification
  class Exporter
    def self.call(lead_id)
      # implementar
    end
  end
end
```

### 3. Criar testes RSpec
```ruby
# spec/services/qualification/exporter_spec.rb
RSpec.describe Qualification::Exporter do
  # testes com WebMock ou doubles
end
```

### 4. Executar testes
```bash
bundle exec rspec
```

### 5. Revisar com código-reviewer
```bash
code-reviewer --repo /home/gildembergsantos/Documentos/capta_lead
```

---

## 📦 Comandos Úteis

```bash
# Rodar aplicação
bundle exec rails server -b 127.0.0.1 -p 3000

# Rodar Sidekiq
bundle exec sidekiq -q low -q default

# Console Rails
bundle exec rails console

# Gerar migração
bundle exec rails generate migration NomeDaMigracao

# Ver rotas
bundle exec rails routes

# Reset banco (cuidado: apaga dados)
bundle exec rails db:reset

# Verificar Ollama
./bin/ollama_check

# Logs Sidekiq
bundle exec sidekiq -q low -q default -L log/sidekiq.log
```

---

## 📊 URLs da Aplicação

| Página | URL | Função |
|--------|-----|--------|
| Dashboard | `/dashboard` | Métricas, calibração, cards, status Ollama |
| Empresas | `/companies` | CRUD empresas + critérios IA |
| Nova Empresa | `/companies/new` | Formulário criação empresa |
| Editar Empresa | `/companies/:id/edit` | Editar empresa e critérios |
| Ver Empresa | `/companies/:id` | Detalhe empresa + leads |
| Leads | `/leads` | Listagem leads + botão Qualificar |
| Novo Lead | `/leads/new` | Formulário com campos dinâmicos |
| Editar Lead | `/leads/:id/edit` | Editar lead |
| Ver Lead | `/leads/:id` | Detalhe lead + snapshot qualificação |
| Qualificações | `/lead_qualifications` | Lista todas as qualificações IA |
| Ver Qualificação | `/lead_qualifications/:id` | Detalhe qualificação + snapshots |

---

## 🧪 Seeds (Dados Iniciais)

```bash
bundle exec rails db:seed
```

Cria:
- 3 empresas: Contábil Norte, Tech Solutions LTDA, Empresa Demo
- 11 leads com diferentes perfis (qualificado, não qualificado, pendente, demo)
- 9 qualificações já processadas com scores variados
- Feature flags ativas para Contábil Norte e Tech Solutions

---

## 📚 Referências

- Tev1 na biblioteca do Ollama — modelo de decisão da Together AI, API `/v1/systemone`
- Xiong et al., ICLR 2024 — Can LLMs Express Their Uncertainty?
- LGPD (Lei 13.709/2018), art. 6º, III
- OWASP Top 10 for LLM Applications
- Sidekiq — Error Handling
- Flipper — feature flags para Ruby
- scikit-learn — Probability calibration
- Google ML Crash Course — Accuracy, precision, recall

---

## ⚠️ Antes de Fazer Push

1. Execute `bundle exec rspec` — deve passar 28/28
2. Execute `code-reviewer` para revisão de segurança
3. Verifique que não há dados sensíveis em `.env` (está no .gitignore)
4. **Atualize a documentação se mudou algo significativo** (veja abaixo)

---

## 📚 Manutenção Contínua da Documentação

Para garantir que o projeto esteja sempre alinhado com sua documentação, siga estas regras:

### Quando Atualizar a Documentação

Sempre que houver alteração nas seguintes áreas, atualize o(s) documento(s) correspondente(s):

| Alteração no Código | Documento a Atualizar |
|---------------------|----------------------|
| Novo modelo, migração ou campo | `AGENTS.md`, `README.md` |
| Novo serviço ou alteração em `app/services/qualification/` | `app/services/qualification/README.md`, `AGENTS.md` |
| Nova view, controller ou rota | `AGENTS.md`, `README.md` (tabela de URLs) |
| Nova regra de LGPD ou sanitização | `docs/LGPD.md` |
| Mudança de deploy, variáveis de ambiente, Docker | `docs/DEPLOY.md` |
| Mudança de arquitetura ou decisões de design | `docs/ARCHITECTURE.md` |
| Novo teste ou mudança de convenção de teste | `spec/TESTING.md` |

### Checklist de Verificação (antes de cada push)

```markdown
- [ ] Testes passam: `bundle exec rspec` (28/28)
- [ ] Documentação reflete mudanças no código
- [ ] Estrutura de diretórios em `AGENTS.md` e `README.md` está atualizada
- [ ] Tabela de URLs no `README.md` reflete todas as rotas ativas
- [ ] Nenhum dado sensível em `.env` (está no .gitignore)
- [ ] Referências cruzadas entre documentos estão consistentes
```

### Comando Rápido de Verificação

```bash
# Verificar se todos os arquivos listados no AGENTS.md existem
cd /home/gildembergsantos/Documentos/capta_lead

# Verificar rotas ativas vs documentadas
bundle exec rails routes

# Verificar se modelos correspondem à documentação
bundle exec rails console
```

---
