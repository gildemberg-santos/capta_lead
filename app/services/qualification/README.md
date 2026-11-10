# Serviços de Qualificação — CaptaLead

Documentação técnica dos serviços de qualificação de leads localizados em `app/services/qualification/`.

---

## 📋 Visão Geral

Os serviços de qualificação são o núcleo do CaptaLead. Eles orquestram o fluxo completo:
1. Sanitização de dados pessoais (LGPD)
2. Chamada ao modelo de decisão (Tev1 via Ollama)
3. Interpretação da nota (probabilidade → status + confiança)
4. Persistência com snapshot (auditoria)

---

## 🗂️ Arquivos e Responsabilidades

| Arquivo | Classe | Responsabilidade |
|---------|--------|-----------------|
| `answer_sanitizer.rb` | `Qualification::AnswerSanitizer` | Filtro LGPD: remove/mascará dados pessoais |
| `ollama_client.rb` | `Qualification::OllamaClient` | Cliente HTTP para `/v1/systemone` do Tev1 |
| `interpreter.rb` | `Qualification::Interpreter` | Nota → status + confiança |
| `evaluator.rb` | `Qualification::Evaluator` | Orquestra todo o fluxo |
| `enqueuer.rb` | `Qualification::Enqueuer` | Feature flag, idempotência, enfileira job |
| `metrics.rb` | `Qualification::Metrics` | Precisão, recall, acurácia, Brier, calibração |

---

## 🔄 Fluxo de Execução

```
Lead criado
    │
    ▼
Enqueuer.call(lead) ──────────────────────┐
    │                                     │
    ▼                                     │
Verifica demo?                            │
    │                                     │
    ▼                                     │
Verifica Flipper.enabled?                 │
    │                                     │
    ▼                                     │
Verifica idempotência (já existe?)        │
    │                                     │
    ▼                                     │
Cria LeadQualification(pending)           │
    │                                     │
    ▼                                     │
QualifyLeadJob.perform_async(lead.id)     │
    │                                     │
    ▼                                     │
Evaluator.new(lead).call                  │
    │                                     │
    ├──▶ AnswerSanitizer.call(fields)     │
    │         │                           │
    │         ▼                           │
    │    answers (sem dados pessoais)     │
    │         │                           │
    │         ▼                           │
    ├──▶ OllamaClient.call(answers, cr)   │
    │         │                           │
    │         ▼                           │
    │    { probability: 0.83, model: "…" }│
    │         │                           │
    │         ▼                           │
    ├──▶ Interpreter.call(prob, thr)      │
    │         │                           │
    │         ▼                           │
    │    { status: "qualified",           │
    │      confidence: "high" }           │
    │         │                           │
    │         ▼                           │
    └──▶ LeadQualification.upsert(...)    │
                                              │
    ▼                                       │
Resultado gravado no banco                  │
    │                                       │
    ▼                                       │
Disponível na UI                            │
```

---

## 🧩 Serviço por Serviço

### AnswerSanitizer

**Arquivo:** `app/services/qualification/answer_sanitizer.rb`

**Método principal:** `self.call(fields)`

**Entrada:** Array de hashes `[{ "label" => "...", "type" => "...", "value" => "..." }]`

**Saída:** Hash `{ "label" => "valor_sanitizado", ... }`

**Regras:**
1. Remove campos cujo tipo esteja em `PERSONAL_TYPES`
2. Aplica máscara de regex em texto livre (email, CPF, CNPJ, phone)
3. Ignora campos com valor vazio
4. Ordem: CNPJ antes de CPF (evita corte pelo meio)

**Exemplo:**
```ruby
Qualification::AnswerSanitizer.call([
  { "label" => "Telefone", "type" => "phone", "value" => "(11) 99999-0000" },
  { "label" => "Empresa", "type" => "text", "value" => "ABC Ltda" }
])
# => { "Empresa" => "ABC Ltda" }
```

---

### OllamaClient

**Arquivo:** `app/services/qualification/ollama_client.rb`

**Método principal:** `self.call(answers:, criteria:)`

**Entrada:**
- `answers`: Hash de respostas sanitizadas `{ "label" => "valor" }`
- `criteria`: Hash com `instructions`, `qualified`, `not_qualified`, `threshold`

**Saída:** `{ probability: Float, model: String }`

**Erros:**
- `TransientError`: serviço fora do ar, timeout, 5xx → pode retry
- `InvalidResponse`: erro 4xx, resposta fora do formato, noul ausente, fora de 0-1 → não retry

**Defesas:**
- Dados do lead vão em `state`, pergunta/critérios em `questions` (separação contra injeção de prompt)
- Validação de intervalo 0–1 feita no Ruby

---

### Interpreter

**Arquivo:** `app/services/qualification/interpreter.rb`

**Método principal:** `self.call(probability, threshold: 0.5)`

**Entrada:**
- `probability`: Float entre 0 e 1
- `threshold`: Float entre 0 e 1 (padrão 0.5)

**Saída:** `Qualification::Interpreter::Result` com `status` e `confidence`

**Regras de confiança (distância do limiar):**
| Distância | Confiança |
|-----------|-----------|
| >= 0.3 | high |
| >= 0.1 | medium |
| < 0.1 | low |

**Status:**
- `probability >= threshold` → `"qualified"`
- `probability < threshold` → `"not_qualified"`

---

### Evaluator

**Arquivo:** `app/services/qualification/evaluator.rb`

**Método principal:** `self.call`

**Fluxo:**
1. Obtém critérios da empresa (ou default)
2. Sanitiza respostas do lead
3. Se não há respostas relevantes → `unclassified` com erro "sem respostas relevantes"
4. Chama OllamaClient
5. Interpreta a nota com o limiar da empresa
6. Grava com `upsert` (idempotente via índice único em `lead_id`)

**Tratamento de erros:**
- `InvalidResponse` → grava `unclassified` com mensagem de erro, não propaga
- `TransientError` → propaga para o Sidekiq retry

---

### Enqueuer

**Arquivo:** `app/services/qualification/enqueuer.rb`

**Método principal:** `self.call(lead)`

**Verificações (em ordem):**
1. `lead.demo?` → não enfileira (leads de demonstração)
2. `Flipper.enabled?(:lead_qualification, lead.company)` → feature flag
3. `LeadQualification.exists?(lead_id: lead.id)` → idempotência (não duplica)

**Se tudo passar:**
1. Cria `LeadQualification(status: "pending")`
2. `QualifyLeadJob.perform_async(lead.id)`

**Tratamento de erros:**
- `RecordNotUnique` → ignora (condição de corrida)
- `StandardError` → loga erro, não derruba a sincronização

---

### Metrics

**Arquivo:** `app/services/qualification/metrics.rb`

**Método principal:** `self.call(rows)`

**Entrada:** Array de hashes com `:predicted`, `:actual`, `:score`

**Saída:** Hash com:
- `matriz`: `{ vp:, fp:, fn:, vn: }`
- `acurácia`, `precisão`, `recall`
- `brier`: Float ou nil
- `calibracao`: Array de faixas com nota média vs conversão real

**Execução via Rake:**
```bash
bundle exec rails qualification:metrics
```

---

## 🧪 Como Adicionar um Novo Tipo de Questão

O Tev1 suporta três tipos: `noul`, `choice`, `score`. Atualmente apenas `noul` é usado.

Para adicionar suporte a `choice`:

1. **Atualizar `OllamaClient`:**
   ```ruby
   QUESTION_KEY = "qualificado"
   QUESTION_TYPE = "choice"  # ou "score"
   ```

2. **Atualizar payload** em `ollama_client.rb` para incluir `options` (para choice) ou `rubric` (para score)

3. **Atualizar `Interpreter`** para interpretar o novo tipo de resposta

4. **Criar testes** em `spec/services/qualification/ollama_client_spec.rb`

---

## 🧪 Como Testar

Todos os serviços usam WebMock para simular chamadas HTTP — não é necessário ter o Ollama rodando.

```bash
# Executar todos os testes de qualificação
bundle exec rspec spec/services/qualification/

# Executar um serviço específico
bundle exec rspec spec/services/qualification/evaluator_spec.rb

# Formato documentação
bundle exec rspec spec/services/qualification/ --format documentation
```

**Exemplo de teste com WebMock:**
```ruby
stub_request(:post, url)
  .to_return(status: 200, body: { answers: { qualificado: { noul: 0.83 } } }.to_json)

expect(client.call(answers:, criteria:))
  .to eq(probability: 0.83, model: "tev1:4b")
```

---

## ⚠️ Cuidados de Produção

1. **Digest do modelo**: A tag `tev1:4b` pode mudar após `ollama pull`. Registre o digest para reprodutibilidade.
2. **Limite de contexto**: Tev1 tem ~2.000 tokens. Mantenha critérios < 1.000 caracteres.
3. **Calibração**: A nota não é chance de venda. Use para ordenar, não para prometer.
4. **Grupo de controle**: Deixe parte dos vendedores sem ver a classificação para evitar viés.
5. **Ollama acessível**: Em Docker, use `http://host.docker.internal:11434` ou nome do serviço.