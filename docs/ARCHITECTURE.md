# Arquitetura — CaptaLead

Visão geral das decisões de arquitetura do projeto CaptaLead, um sistema de qualificação de leads com IA local (Tev1 via Ollama) em Ruby on Rails 7.1.

---

## 🎯 Objetivo

Classificar leads como qualificados ou não usando um modelo de decisão local (Tev1), com foco em:
- **Privacidade**: dados pessoais não saem da infraestrutura (LGPD)
- **Confiabilidade**: não confiar cegamente na saída do modelo; validar no Ruby
- **Auditoria**: guardar snapshot de respostas e critérios para explicar decisões meses depois
- **Resiliência**: não travar a aplicação quando a IA cai; processamento assíncrono com retry

---

## 🏗️ Diagrama de Componentes

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   Lead      │─────▶│  Enqueuer    │─────▶│  Sidekiq Job    │
│  (form)     │      │  (Flipper)   │      │  QualifyLeadJob │
└─────────────┘      └──────────────┘      └─────────────────┘
                                               │
                                               ▼
                                       ┌───────────────┐
                                       │  Evaluator    │
                                       │  (orquestra)  │
                                       └───────┬───────┘
                                               │
        ┌──────────────┐  ┌──────────────┐  ┌─▼─────────────┐
        │ AnswerSanitizer│ │ OllamaClient│ │ Interpreter   │
        │ (LGPD + regex) │ │ (/v1/systemone)│ │ (status +     │
        └──────────────┘  └──────────────┘  │ confidence)   │
                                             └───────────────┘
                                               │
                                               ▼
                                       ┌───────────────┐
                                       │ LeadQualification│
                                       │ (upsert + snapshot)│
                                       └───────────────┘
```

---

## 🧱 Camadas

### 1. Interface (Views + Controllers)
- **Controllers**: `companies_controller.rb`, `leads_controller.rb`, `dashboard_controller.rb`, `lead_qualifications_controller.rb`
- **Views**: ERB com Bootstrap 5, design system próprio em `capta_lead.css`
- **JavaScript**: `lead_form_controller.js` para campos dinâmicos do formulário

### 2. Serviços de Qualificação (Núcleo de IA)
Localizados em `app/services/qualification/`:
- **AnswerSanitizer**: filtro LGPD (tipos + regex)
- **OllamaClient**: chamada HTTP `/v1/systemone` ao Tev1
- **Interpreter**: interpretação de nota → status + confiança
- **Evaluator**: orquestra sanitização → modelo → interpretação → persistência
- **Enqueuer**: feature flag, idempotência, enfileira job
- **Metrics**: precisão, recall, acurácia, Brier, calibração

### 3. Processamento Assíncrono
- **Sidekiq**: `QualifyLeadJob` na fila `low`, retry 3
- `sidekiq_retries_exhausted`: marca como `failed` se todas as tentativas falharem

### 4. Persistência
- **PostgreSQL** com `jsonb` para `form_fields`, `answers_snapshot`, `criteria_snapshot`, `qualification_criteria`, `field_sets.fields`
- Índice único em `lead_id` nas `lead_qualifications` (impede duplicidade)
- `Flipper` para feature flags por empresa (ActiveRecord adapter)

### 5. Conjuntos de Campos (Field Sets)
- `field_sets` pertence a uma empresa (`name` + `fields` jsonb com `{label, type}`)
- Os valores ficam sempre no `form_fields` do lead; não há tabela de junção lead↔conjunto
- Aplicação é transitória no formulário (JavaScript): filtra por empresa, remove linhas vazias e evita labels duplicados
- Reprocessar/editar o conjunto depois não altera leads já preenchidos (snapshot natural)

---

## 🔄 Fluxo de Dados

```
1. Usuário cadastra lead com form_fields (JSON array)
2. Usuário aciona "Qualificar" na tela do lead (POST /leads/:id/qualify)
3. Verificações: demo?, Flipper.enabled?, já existe qualificação?
4. Cria LeadQualification(status: "pending")
5. Sidekiq job executa QualifyLeadJob.perform_async(lead.id)
6. Evaluator.new(lead).call:
   a. AnswerSanitizer.call(form_fields) → remove/mascará dados pessoais
   b. OllamaClient.call(answers, criteria) → POST /v1/systemone
   c. Interpreter.call(probability, threshold) → status + confidence
   d. LeadQualification.upsert(...) → grava com snapshot
7. Resultado disponível na UI
```

---

## 🛡️ Defesas em Camadas

| Camada | Defesa | Arquivo |
|--------|--------|---------|
| 1ª | state vs questions separados (lead em state, não na pergunta) | `ollama_client.rb` |
| 2ª | Validação de intervalo 0–1 no Ruby | `ollama_client.rb` |
| 3ª | Filtro LGPD por tipo + regex | `answer_sanitizer.rb` |
| 4ª | TransientError vs InvalidResponse (só retry transitório) | `ollama_client.rb` |
| 5ª | Upsert com índice único (idempotência) | `evaluator.rb` |
| 6ª | Sidekiq retry com exaustão → `failed` | `qualify_lead_job.rb` |

---

## 🧠 Modelo de Decisão (Tev1)

- **API**: `/v1/systemone` (não é chat)
- **Entrada**: `state` (respostas do lead), `questions` (pergunta + critérios)
- **Saída**: `answers.qualificado.noul` (probabilidade 0–1)
- **Tipos suportados**: noul (true/false), choice, score
- **Contexto**: ~2.000 tokens; critérios limitados a 1.000 caracteres
- **Limite**: validação 0–1 feita no Ruby, não no modelo

---

## 📊 Métricas e Calibração

Calculadas em `Qualification::Metrics`:
- **Matriz de confusão**: VP, FP, FN, VN
- **Acurácia**, **Precisão**, **Recall**
- **Brier Score**: qualidade da probabilidade
- **Calibração por faixa**: nota média vs conversão real em buckets de 0.2

Execução: `bundle exec rails qualification:metrics`

---

## ⚖️ Trade-offs

| Decisão | Prós | Contras |
|---------|------|---------|
| Modelo local (Ollama) | Dados não saem de casa, sem custo por chamada | Requer hardware local, manutenção do modelo |
| jsonb para critérios | Flexível, esquema evolui sem migration | Sem validação de esquema no banco (feito no modelo) |
| Sidekiq assíncrono | Não trava a requisição HTTP | Resultado não é imediato |
| Upsert com índice único | Impede duplicidade | Requer índice único no banco |
| Flipper por empresa | Ativação gradual, controle por cliente | Complexidade adicional |

---

## 🔮 Extensões Planejadas

- Calibração de nota com regressão logística (Platt) ou isotônica
- Grupo de controle (A/B) para validar viés do modelo
- Digest do modelo (registro de versão exata do tev1)
- Teste de carga do Ollama local
- Remoção da feature flag após validação