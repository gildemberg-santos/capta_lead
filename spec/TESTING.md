# Testes — CaptaLead

Guia de convenções e práticas de teste no projeto CaptaLead.

---

## 📊 Visão Geral

- **Framework:** RSpec 7.1
- **Simulação de HTTP:** WebMock (não chama o Ollama real nos testes)
- **Fixtures:** FactoryBot
- **Banco de dados:** PostgreSQL com transações (rollback após cada teste)
- **Total:** 28 exemplos, 0 falhas

---

## 🏗️ Estrutura de Testes

```
spec/
├── factories/
│   ├── companies.rb          # Factory para Company
│   ├── leads.rb              # Factory para Lead
│   └── lead_qualifications.rb # Factory para LeadQualification
├── services/qualification/
│   ├── answer_sanitizer_spec.rb      # Filtro LGPD
│   ├── ollama_client_spec.rb         # Cliente Ollama (WebMock)
│   ├── interpreter_spec.rb           # Interpretação de nota
│   ├── evaluator_spec.rb             # Orquestração completa
│   ├── enqueuer_spec.rb              # Feature flag, idempotência
│   └── metrics_spec.rb               # Matriz de confusão, calibração
├── spec_helper.rb
└── rails_helper.rb
```

---

## 🏭 Factories

Localizadas em `spec/factories/`. Usar `create` ou `build` conforme necessário.

### Company
```ruby
create(:company)                                    # Empresa genérica
create(:company, :contabil_norte)                   # Com critérios específicos
create(:company, :demo)                             # Empresa de demonstração
```

### Lead
```ruby
create(:lead)                                       # Com form_fields padrão
create(:lead, :com_funcionarios)                    # Apenas campos relevantes
create(:lead, :sem_respostas_relevantes)            # Apenas dados pessoais
```

### LeadQualification
```ruby
create(:lead_qualification)                         # Status pending, sem score
```

---

## 🧪 Convenções de Teste

### 1. Usar `described_class` quando possível
```ruby
RSpec.describe Qualification::AnswerSanitizer do
  it "remove dados pessoais" do
    expect(described_class.call(fields)).to eq(...)
  end
end
```

### 2. Usar `instance_double` para mockar serviços externos
```ruby
let(:client) { instance_double(Qualification::OllamaClient) }

allow(client).to receive(:call).and_return(probability: 0.82, model: "tev1:4b")
```

### 3. Simular chamadas HTTP com WebMock
```ruby
stub_request(:post, url)
  .to_return(status: 200, body: { answers: { qualificado: { noul: 0.83 } } }.to_json)
```

### 4. Testar erros
```ruby
it "trata erro 5xx como transitório" do
  stub_request(:post, url).to_return(status: 503)
  expect { client.call(answers:, criteria:) }
    .to raise_error(described_class::TransientError)
end
```

### 5. Testar atributos com `have_attributes`
```ruby
expect(lead.reload.lead_qualification)
  .to have_attributes(status: "qualified", confidence: "high")
```

---

## 🎯 O Que Testar (por serviço)

### AnswerSanitizer
- [x] Remove dados pessoais pelo tipo (não pelo rótulo)
- [x] Máscara dados em texto livre (CPF, CNPJ, email, phone)
- [x] Ordem CNPJ antes de CPF
- [x] Ignora campos vazios
- [ ] Mais padrões de endereço (futuro)

### OllamaClient
- [x] Envia `state` separado da pergunta
- [x] Lê o `noul` da resposta
- [x] Erro 5xx → TransientError
- [x] Probabilidade fora de 0-1 → InvalidResponse
- [x] `noul` ausente → InvalidResponse
- [ ] Erro 4xx → InvalidResponse (adicionar)
- [ ] Resposta JSON malformada → InvalidResponse (adicionar)

### Interpreter
- [x] Nota acima do limiar → qualified
- [x] Nota abaixo do limiar → not_qualified
- [x] Confiança alta/média/baixa por distância
- [x] Limiar personalizado
- [ ] Limiar exato (0.5 == 0.5)

### Evaluator
- [x] Grava classificação quando modelo responde
- [x] Resposta inválida → unclassified
- [x] Erro transitório sobe para Sidekiq
- [x] Sem respostas relevantes → unclassified
- [x] Limiar personalizado da empresa
- [ ] Upsert idempotente (condição de corrida)

### Enqueuer
- [x] Não enfileira lead de demonstração
- [x] Respeita feature flag
- [x] Não duplica qualificação existente
- [x] Cria pendente + enfileira job
- [x] Registra erro sem derrubar sincronização

### Metrics
- [x] Matriz de confusão (VP, FP, FN, VN)
- [x] Acurácia, precisão, recall
- [x] Brier score
- [x] Calibração por faixa
- [x] Denominador zero → nil
- [ ] Calibração com dados reais de produção

---

## 🔧 Como Adicionar um Novo Teste

### Exemplo: Testar um novo serviço `Qualification::Exporter`

1. Criar o arquivo de especificação:
```ruby
# spec/services/qualification/exporter_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::Exporter do
  it "exporta qualificações para CSV" do
    # implementar teste
  end
end
```

2. Executar:
```bash
bundle exec rspec spec/services/qualification/exporter_spec.rb
```

3. Verificar cobertura:
```bash
# Se houver SimpleCov configurado
bundle exec rspec --format documentation
```

---

## ⚠️ Regras Importantes

| Regra | Por que |
|-------|---------|
| Não chamar o Ollama real nos testes | Testes devem ser rápidos e determinísticos |
| Usar WebMock para simular HTTP | Isola o código do serviço externo |
| Usar FactoryBot para dados | Consistência e reutilização |
| Transações de banco (rollback) | Isola testes entre si |
| Testar erros e exceções | Garante resiliência |
| Não testar comportamento do modelo IA | Isso é medido no relatório de métricas, não nos testes unitários |

---

## 📦 Comandos Úteis

```bash
# Rodar todos os testes
bundle exec rspec

# Rodar apenas serviços de qualificação
bundle exec rspec spec/services/qualification/

# Formato documentação (mais verboso)
bundle exec rspec --format documentation

# Rodar um arquivo específico
bundle exec rspec spec/services/qualification/evaluator_spec.rb

# Com variáveis de ambiente (se necessário)
DATABASE_HOST=localhost DATABASE_PORT=5432 \
  DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres \
  REDIS_URL=redis://localhost:6379/0 \
  bundle exec rspec
```

---

## 🚨 Problemas Comuns

| Problema | Solução |
|----------|---------|
| `FactoryBot::DuplicateDefinitionError` | Não carregar factories duas vezes (usar `spec_helper` + `rails_helper` corretamente) |
| `ActiveRecord::ConnectionNotEstablished` | Banco não está rodando (iniciar `docker compose up -d db redis`) |
| WebMock bloqueia conexão real | Esperado — não remover o `disable_net_connect!` |
| Teste flaky com ordem aleatória | Usar `bundle exec rspec --seed <número>` para reproduzir |