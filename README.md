# CaptaLead — Qualificação de leads com IA na prática

Projeto fictício baseado no tutorial *"Qualificação de leads com IA na prática: do Ollama ao Sidekiq em um projeto Rails"*.

Uma plataforma SaaS de captação de leads feita em Ruby on Rails que usa um modelo de decisão local (Tev1 da Together AI, rodando no Ollama) para classificar leads como qualificados ou não, com filtro de dados pessoais (LGPD), job assíncrono (Sidekiq), testes (RSpec) e relatório de métricas.

## O que o projeto faz

1. **Tev1 via Ollama** — modelo de decisão local (não sai da sua infraestrutura)
2. **Tabelas** — `lead_qualifications` com snapshot de respostas e critérios; `qualification_criteria` (jsonb) em `companies`
3. **Filtro de dados pessoais** — remove dados pessoais antes de enviar ao modelo (princípio da necessidade da LGPD)
4. **Chamada ao Ollama** — API `/v1/systemone` do Tev1, que devolve probabilidade tipada
5. **Interpretação da nota** — compara com o limiar da empresa e calcula faixa de confiança
6. **Job Sidekiq** — processamento assíncrono com retry e tratamento de erros
7. **Testes RSpec** — coberta com WebMock (não chama a IA nos testes de unidade)
8. **Métricas** — precisão, recall, acurácia, Brier score e calibração

## Estrutura do projeto

```
capta_lead/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── companies_controller.rb      # CRUD empresas + critérios IA
│   │   ├── dashboard_controller.rb      # métricas, calibração, status Ollama
│   │   ├── lead_qualifications_controller.rb  # listagem e detalhe qualificações
│   │   └── leads_controller.rb          # CRUD leads + formulário dinâmico + qualificar
│   ├── helpers/
│   │   └── application_helper.rb        # lead_answer, criteria_value, preview_criteria
│   ├── javascript/
│   │   └── controllers/
│   │       └── lead_form_controller.js  # campos dinâmicos, modo Visual/JSON
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── company.rb                   # Flipper::Identifier, DEFAULT_CRITERIA (BANT), validação JSON
│   │   ├── lead.rb                      # validação form_fields, campos pessoais vs negócio
│   │   └── lead_qualification.rb        # enum status, snapshots jsonb
│   ├── services/qualification/
│   │   ├── answer_sanitizer.rb          # filtro de dados pessoais (tipos + regex)
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
│   └── sidekiq/
│       └── qualify_lead_job.rb          # fila low, retry 3, sidekiq_retries_exhausted
├── assets/
│   └── stylesheets/
│       └── capta_lead.css               # design system profissional (cores, cards, badges)
├── db/migrate/
│   ├── 20261110000000_create_companies.rb
│   ├── 20261110000001_create_leads.rb
│   ├── 20261110000002_create_lead_qualifications.rb
│   ├── 20261110000003_add_qualification_criteria_to_companies.rb
│   └── 20261110143334_create_flipper_tables.rb
├── spec/
│   ├── factories/
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
│   └── initializers/sidekiq.rb          # conexão Redis
├── Dockerfile
├── docker-compose.yml                   # postgres, redis, web, sidekiq (Ollama é local)
├── bin/
│   └── ollama_check                     # valida Ollama local e modelo Tev1
├── public/javascripts/
│   └── lead_form_controller.js          # JS de campos dinâmicos (cópia para uso direto)
├── docs/
│   ├── ARCHITECTURE.md                  # decisões de arquitetura
│   ├── DEPLOY.md                        # deploy em produção
│   └── LGPD.md                          # proteção de dados pessoais
├── app/services/qualification/README.md # documentação dos serviços de IA
├── spec/TESTING.md                      # convenções de teste
├── .env.example
├── Gemfile
└── README.md
```

## Pré-requisitos

- Ruby 3.4+
- Rails 7.1+
- PostgreSQL (usa `jsonb`)
- Redis (para Sidekiq)
- **Ollama local já instalado e rodando** (0.35+, com o modelo `tev1:4b` baixado)
- Sidekiq e Flipper

## Instalação

### 1. Variáveis de ambiente

Copie o exemplo e ajuste se necessário:

```bash
cp .env.example .env
source .env
```

### 2. Instalar gems

```bash
bundle install
```

### 3. Banco de dados

```bash
bundle exec rails db:create db:migrate
bundle exec rails db:seed
```

### 4. Verificar o Ollama local (não é necessário subir outro via Docker)

Se você já tem o Ollama rodando localmente, basta confirmar que ele está no ar e com o modelo Tev1:

```bash
# Dá execução na primeira vez
chmod +x bin/ollama_check

# Verifica se o Ollama responde e se o modelo tev1:4b está disponível
./bin/ollama_check
```

O script verifica:
- Se o Ollama responde em `http://localhost:11434`
- Se o modelo `tev1:4b` está baixado localmente
- Se a API de decisão `/v1/systemone` retorna um `noul`

Se o modelo ainda não estiver baixado:

```bash
ollama pull tev1:4b
```

Sem GPU NVIDIA configurada, o Tev1 roda na CPU (mais lento, mas funciona).

### 5. Rodar a aplicação

```bash
bundle exec rails server
```

E em outro terminal, o Sidekiq:

```bash
bundle exec sidekiq -q low -q default
```

## Usando Docker Compose

```bash
docker compose up -d
```

Isso sobe: **PostgreSQL, Redis, Rails (web) e Sidekiq**.

O Ollama **não** é mais um serviço do compose — a aplicação aponta para o seu Ollama local via `http://host.docker.internal:11434` (ou `localhost:11434` quando rodando fora do Docker). Certifique-se de que o Ollama local já esteja rodando e com o modelo `tev1:4b` antes de iniciar:

```bash
./bin/ollama_check
```

## Testes

```bash
bundle exec rspec
```

Os testes simulam chamadas HTTP ao Ollama com WebMock (host `http://ollama.test`), então não é necessário ter o modelo rodando para executar a suíte.

```bash
# 28 examples, 0 failures
```

## Relatório de métricas

Após preencher o campo `outcome` ("won" ou "lost") em algumas qualificações, rode:

```bash
bundle exec rails qualification:metrics
```

Exemplo de saída (dados fictícios do tutorial):

```ruby
{ matriz: { vp: 26, fp: 83, fn: 8, vn: 183 },
  acuracia: 0.697, precisao: 0.239, recall: 0.765, brier: 0.217,
  calibracao: [
    { faixa: "0.0–0.2", leads: 71, nota_media: 0.12, conversao_real: 0.0 },
    { faixa: "0.2–0.4", leads: 95, nota_media: 0.29, conversao_real: 0.063 },
    { faixa: "0.4–0.6", leads: 43, nota_media: 0.48, conversao_real: 0.209 },
    { faixa: "0.6–0.8", leads: 53, nota_media: 0.69, conversao_real: 0.17 },
    { faixa: "0.8–1.0", leads: 38, nota_media: 0.88, conversao_real: 0.263 }
  ] }
```

## Sistema de Empresas e Critérios de Qualificação

A criação e edição de empresas inclui um formulário profissional para gerenciar os critérios de qualificação IA:

- **Instruções para o modelo**: Orientações gerais enviadas ao Tev1
- **Critério QUALIFICADO**: Condições para lead ser considerado qualificado (TRUE)
- **Critério NÃO QUALIFICADO**: Condições para lead ser considerado não qualificado (FALSE)
- **Limiar de aprovação**: Nota mínima (0-1) para classificar como qualificado, com slider visual
- **Preview JSON**: Visualização em tempo real do JSON enviado ao modelo
- **Botão Restaurar Padrão**: Volta para os critérios BANT padrão

Exemplo de JSON dos critérios:

```json
{
  "instructions": "Este lead é qualificado para contratar um escritório de contabilidade?",
  "qualified": "Empresa com 5 ou mais funcionários, faturamento acima de R$ 50 mil/mês e contratação em até 60 dias.",
  "not_qualified": "MEI sem funcionários, quem só quer cotação de preço ou sem previsão de contratação.",
  "threshold": 0.5
}
```

## Sistema de Campos Dinâmicos (Formulário de Lead)

A criação e edição de leads usa um formulário dinâmico que permite:

- **Adicionar/remover campos** quantos forem necessários
- **Tipos pré-definidos**: texto, seleção, telefone, WhatsApp, e-mail, CPF, CNPJ, endereço, texto longo, senha
- **Modo Visual** (padrão) e **Modo JSON** para edição direta
- **Sanitização automática LGPD**: campos com tipos `phone`, `email`, `whatsapp`, `cpf`, `cnpj`, `address` ou `password` são automaticamente mascarados antes de enviar ao modelo IA

Exemplo de JSON gerado:

```json
[
  { "label": "Quantos funcionários?", "type": "select", "value": "De 11 a 50" },
  { "label": "Quando pretende contratar?", "type": "select", "value": "Nos próximos 30 dias" },
  { "label": "Melhor contato", "type": "phone", "value": "(11) 99999-0000" },
  { "label": "Conte sua necessidade", "type": "textarea", "value": "Preciso de contabilidade." }
]
```

## Acesso à aplicação

Após iniciar o servidor (`bundle exec rails server`), acesse **http://localhost:3000/**:

| Página | URL | Função |
|--------|-----|--------|
| **Dashboard** | `/dashboard` | Visão geral: cards de estatísticas, barras de progresso, métricas de desempenho, calibração, status do Ollama |
| **Empresas** | `/companies` | CRUD completo: criar, editar, excluir empresas e gerenciar critérios de qualificação IA |
| **Nova Empresa** | `/companies/new` | Formulário com nome, modo demo e critérios (instruções, qualificado, não qualificado, limiar) |
| **Editar Empresa** | `/companies/:id/edit` | Editar empresa e critérios de qualificação |
| **Ver Empresa** | `/companies/:id` | Detalhe da empresa e seus leads |
| **Leads** | `/leads` | Listagem com status da qualificação e score; botão "Qualificar" para enfileirar job Sidekiq |
| **Novo Lead** | `/leads/new` | Formulário com seleção de empresa, modo demo e campos dinâmicos do formulário de captação |
| **Editar Lead** | `/leads/:id/edit` | Editar lead e seus campos de formulário |
| **Ver Lead** | `/leads/:id` | Detalhe do lead com snapshot de qualificação e botão "Reprocessar" |
| **Reprocessar Lead** | `POST /leads/:id/requalify` | Re-enfileira qualquer qualificação existente (volta para pending) |
| **Qualificações** | `/lead_qualifications` | Lista completa de todas as avaliações IA com status, score, confiança e modelo |
| **Ver Qualificação** | `/lead_qualifications/:id` | Detalhe da qualificação com snapshots de respostas e critérios |

## Principais decisões de projeto

| Decisão | Motivo |
|---------|--------|
| Tev1 via `/v1/systemone` | API de decisão tipada, não chat; evita promanção em prosa |
| state vs questions separados | Primeira defesa contra injeção de prompt (dados do lead vão em state) |
| Validação 0–1 no Ruby | Regra de negócio não fica nas mãos do modelo |
| Upsert com índice único | Impede avaliações duplicadas para o mesmo lead |
| TransientError vs InvalidResponse | Só erros transitórios são retryados pelo Sidekiq |
| Filtro por tipo + regex | LGPD: não enviar dados pessoais ao modelo |
| Snapshot de respostas e critérios | Auditoria: é possível explicar meses depois por que a nota foi aquela |

## Antes de ir para produção

Conforme o tutorial, antes de usar com clientes reais:

1. **Grupo de controle** — deixe parte dos vendedores sem ver a classificação
2. **Digest do modelo** — registre o digest do `tev1:4b` (a tag pode mudar após `ollama pull`)
3. **Teste de carga** — meça latência, memória e concorrência do Ollama local
4. **Limite de 1.000 caracteres** nos critérios (contexto do Tev1 ≈ 2.000 tokens)
5. **Ollama acessível pelos workers** — no Docker: `http://host.docker.internal:11434`
6. **Retenção dos snapshots** — defina por quanto tempo guardar dados do lead
7. **Remover a feature flag** — toda flag temporária precisa de data para sair

## Referências

- Tev1 na biblioteca do Ollama — modelo de decisão da Together AI, API `/v1/systemone`
- Xiong et al., ICLR 2024 — Can LLMs Express Their Uncertainty?
- LGPD (Lei 13.709/2018), art. 6º, III
- OWASP Top 10 for LLM Applications
- Sidekiq — Error Handling
- Flipper — feature flags para Ruby

## Licença

Projeto fictício para fins educacionais.

---

## 📚 Manutenção da Documentação

Para garantir que a documentação esteja sempre alinhada com o código, atualize o(s) documento(s) correspondente(s) sempre que fizer alterações significativas:

| Alteração | Documento a Atualizar |
|-----------|----------------------|
| Novo modelo, migração, campo | `AGENTS.md`, `README.md` |
| Novo serviço ou alteração em IA | `app/services/qualification/README.md`, `AGENTS.md` |
| Nova view, controller, rota | `AGENTS.md`, `README.md` (tabela de URLs) |
| Nova regra de LGPD | `docs/LGPD.md` |
| Mudança de deploy/Docker | `docs/DEPLOY.md` |
| Mudança de arquitetura | `docs/ARCHITECTURE.md` |
| Nova convenção de teste | `spec/TESTING.md` |

### Checklist antes de Push

- [ ] `bundle exec rspec` passa (28/28)
- [ ] Documentação reflete mudanças no código
- [ ] Estrutura de diretórios em `AGENTS.md` e `README.md` está atualizada
- [ ] Tabela de URLs no `README.md` reflete todas as rotas ativas
- [ ] Nenhum dado sensível em `.env`

Veja `AGENTS.md` para o guia completo de operação e manutenção.