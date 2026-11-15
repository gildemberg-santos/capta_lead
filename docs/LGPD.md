# LGPD — Proteção de Dados Pessoais

Documentação de como o CaptaLead implementa o princípio da necessidade (art. 6º, III da LGPD) na qualificação de leads com IA.

---

## 📜 Fundamento Legal

**Lei 13.709/2018 (LGPD), Artigo 6º, III — Princípio da Necessidade:**

> "Limitação da realização do tratamento ao mínimo necessário para a realização de suas finalidades, com os dados relevantes, proporcionais e não excessivos em relação às finalidades do tratamento."

**Aplicação no CaptaLead:** o modelo de IA precisa saber o porte, orçamento, autoridade e prazo do lead (BANT). Não precisa saber nome, telefone, e-mail, CPF ou endereço.

---

## 🔒 Duas Camadas de Proteção

### Camada 1 — Por Tipo de Campo

O cliente pode chamar o telefone de "Melhor contato", mas o tipo continua sendo `phone`. O sanitizador remove campos com tipos pessoais **antes** de enviar ao modelo.

**Tipos removidos (tipo do campo):**
- `name`, `email`, `phone`, `whatsapp`, `cpf`, `cnpj`, `address`, `password`

**Arquivo:** `app/services/qualification/answer_sanitizer.rb`

```ruby
PERSONAL_TYPES = %w[name email phone whatsapp cpf cnpj address password].freeze
```

### Camada 2 — Por Padrão em Texto Livre

Alguém sempre digita o WhatsApp no campo "Conte sua necessidade". O sanitizador aplica regex para mascarar dados pessoais encontrados em texto livre.

**Padrões (ordem importa — CNPJ antes de CPF):**

| Padrão | Regex | Substituição |
|--------|-------|--------------|
| CNPJ | `\b\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}\b` | `[cnpj_removido]` |
| CPF | `\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b` | `[cpf_removido]` |
| Email | `[\w.+-]+@[\w-]+(?:\.[\w-]+)+` | `[email_removido]` |
| Phone | `(?:\+?55\s?)?\(?\b\d{2}\)?\s?9?\d{4}[-\s]?\d{4}\b` | `[phone_removido]` |

**Exemplo:**

```ruby
# Entrada:
fields = [
  { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
  { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" },
  { "label" => "Conte sua necessidade", "type" => "textarea",
    "value" => "Me chama no 85 99999-0000 ou joao@empresa.com. Temos 30 funcionários." }
]

# Saída:
{
  "Quantos funcionários?" => "De 11 a 50",
  "Conte sua necessidade" => "Me chama no [phone_removido] ou [email_removido]. Temos 30 funcionários."
}
```

---

## ⚠️ Limites da Sanitização

**Regex não pega tudo.** Exemplos de dados que podem escapar:
- Endereço por extenso ("Rua das Flores, 123, Centro, São Paulo")
- Nome escrito naturalmente ("me chamo João Silva")
- RG, número de conta bancária

**Tratamento:** a camada de sanitização é uma **redução de risco**, não uma garantia absoluta. Nunca considerar os dados enviados ao modelo como "anônimos" legalmente.

---

## 📦 O Que É Enviado vs O Que Fica

| Dado | Enviado ao Ollama? | Fica no Banco? | Snapshots |
|------|-------------------|----------------|-----------|
| Nome | ❌ Não | ✅ Sim (form_fields) | ❌ Não (removido) |
| Telefone | ❌ Não | ✅ Sim (form_fields) | ❌ Não (mascarado) |
| E-mail | ❌ Não | ✅ Sim (form_fields) | ❌ Não (mascarado) |
| CPF/CNPJ | ❌ Não | ✅ Sim (form_fields) | ❌ Não (mascarado) |
| Endereço | ❌ Não (campo tipo `address`) / ⚠️ se digitado em texto livre | ✅ Sim (form_fields) | ❌ Não (tipo `address`) / ⚠️ Parcial |
| Porte/funcionários | ✅ Sim | ✅ Sim | ✅ Sim |
| Orçamento/faturamento | ✅ Sim | ✅ Sim | ✅ Sim |
| Autoridade/decisor | ✅ Sim | ✅ Sim | ✅ Sim |
| Prazo de contratação | ✅ Sim | ✅ Sim | ✅ Sim |
| Necessidade (texto) | ✅ Sim (mascarado) | ✅ Sim | ✅ Sim (mascarado) |

---

## 🗄️ Retenção de Snapshots

Os snapshots (`answers_snapshot`, `criteria_snapshot`) contêm dados do lead (mesmo que sanitizados).

**Recomendações para produção:**
1. Definir política de retenção (ex: 5 anos, conforme LGPD art. 16)
2. Criar job de limpeza/anônimação de dados antigos
3. Oferecer mecanismo de exclusão (LGPD art. 18 — direito à eliminação)
4. Registrar consentimento para tratamento dos dados

---

## 🧪 Testes Relacionados à LGPD

**Arquivo:** `spec/services/qualification/answer_sanitizer_spec.rb`

Cobertura:
- Remoção por tipo de campo (não por rótulo)
- Máscara de CPF, CNPJ, email, phone em texto livre
- Ordem CNPJ antes de CPF
- Campos com valor vazio ignorados

Exemplo de teste:
```ruby
it "remove dados pessoais pelo tipo do campo, não pelo rótulo" do
  fields = [
    { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" },
    { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" }
  ]
  expect(described_class.call(fields)).to eq("Quantos funcionários?" => "De 11 a 50")
end
```

---

## 📋 Checklist LGPD para Produção

- [ ] Política de privacidade atualizada com finalidade do tratamento
- [ ] Consentimento do lead capturado no formulário
- [ ] Mecanismo de solicitação de exclusão de dados (LGPD art. 18)
- [ ] Política de retenção definida e implementada
- [ ] Log de acesso aos dados de qualificação
- [ ] Análise de impacto à proteção de dados (LGPD art. 38)
- [ ] Treinamento da equipe sobre LGPD
- <|constraint|>ongoing

---

## 🔗 Referências

- LGPD (Lei 13.709/2018), art. 6º, III — Princípio da necessidade
- LGPD, art. 18 — Direitos do titular
- LGPD, art. 38 — Análise de impacto
- OWASP Top 10 for LLM Applications — Injeção de prompt, vazamento de dados