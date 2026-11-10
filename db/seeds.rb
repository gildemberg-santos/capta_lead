# frozen_string_literal: true

# Seeds do CaptaLead — dados fictícios para testar a interface visual
# e o fluxo completo de qualificação de leads com IA.

puts "🌱 Iniciando seeds do CaptaLead..."

# ---------------------------------------------------------------------------
# 1. Empresas
# ---------------------------------------------------------------------------

contabil_norte = Company.find_or_create_by!(name: "Contábil Norte") do |c|
  c.demo = false
  c.qualification_criteria = {
    "instructions" => "Este lead é qualificado para contratar um escritório de contabilidade?",
    "qualified" => "Empresa com 5 ou mais funcionários, faturamento acima de R$ 50 mil/mês e contratação em até 60 dias.",
    "not_qualified" => "MEI sem funcionários, quem só quer cotação de preço ou sem previsão de contratação.",
    "threshold" => 0.5
  }
end

tech_solutions = Company.find_or_create_by!(name: "Tech Solutions LTDA") do |c|
  c.demo = false
  c.qualification_criteria = {
    "instructions" => "Este lead é qualificado para comprar software de gestão?",
    "qualified" => "Empresa com mais de 10 funcionários, faturamento acima de R$ 100 mil/mês e decisor envolvido.",
    "not_qualified" => "Microempresa sem orçamento, sem poder de decisão ou sem necessidade urgente.",
    "threshold" => 0.6
  }
end

demo_empresa = Company.find_or_create_by!(name: "Empresa Demo") do |c|
  c.demo = true
  c.qualification_criteria = {}
end

puts "   Empresas criadas: #{Company.count}"

# ---------------------------------------------------------------------------
# 2. Conjuntos de campos (field sets) reutilizáveis por empresa
# ---------------------------------------------------------------------------

field_sets = {
  contabil_norte => [
    {
      name: "Contabilidade — Padrão",
      fields: [
        { "label" => "Quantos funcionários?", "type" => "select" },
        { "label" => "Quando pretende contratar?", "type" => "select" },
        { "label" => "Melhor contato", "type" => "phone" },
        { "label" => "Conte sua necessidade", "type" => "textarea" }
      ]
    },
    {
      name: "Contato rápido",
      fields: [
        { "label" => "Melhor contato", "type" => "phone" },
        { "label" => "Conte sua necessidade", "type" => "textarea" }
      ]
    }
  ],
  tech_solutions => [
    {
      name: "Software de Gestão — Padrão",
      fields: [
        { "label" => "Quantos funcionários?", "type" => "select" },
        { "label" => "Quando pretende contratar?", "type" => "select" },
        { "label" => "Melhor contato", "type" => "phone" },
        { "label" => "Conte sua necessidade", "type" => "textarea" }
      ]
    }
  ],
  demo_empresa => [
    {
      name: "Dados básicos",
      fields: [
        { "label" => "Quantos funcionários?", "type" => "select" },
        { "label" => "Quando pretende contratar?", "type" => "select" }
      ]
    }
  ]
}

field_sets.each do |company, sets|
  sets.each do |attrs|
    company.field_sets.find_or_create_by!(name: attrs[:name]) do |field_set|
      field_set.fields = attrs[:fields]
    end
  end
end

puts "   Conjuntos de campos criados: #{FieldSet.count}"

# ---------------------------------------------------------------------------
# 3. Leads da Contábil Norte (com qualificações já processadas)
# ---------------------------------------------------------------------------

leads_contabil = [
  # Lead qualificado — score alto
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(11) 98765-4321" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Preciso de contabilidade completa para minha empresa de comércio. Me chama no 11 98765-4321 ou contato@empresa.com.br." }
    ],
    score: 0.92,
    status: "qualified",
    confidence: "high",
    outcome: "won"
  },
  # Lead qualificado — score médio-alto
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 51 a 200" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 60 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(21) 91234-5678" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Somos uma prestadora de serviços e precisamos de assessoria contábil. Email: rh@techsolutions.com.br" }
    ],
    score: 0.78,
    status: "qualified",
    confidence: "high",
    outcome: "won"
  },
  # Lead qualificado — score baixo (perto do limiar)
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 1 a 10" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 90 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(31) 99999-1111" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "MEI aberto há 6 meses, preciso regularizar impostos." }
    ],
    score: 0.53,
    status: "qualified",
    confidence: "low",
    outcome: "lost"
  },
  # Lead não qualificado — score baixo
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "Sou MEI" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Sem previsão" },
      { "label" => "Melhor contato", "type": "phone", "value": "(41) 98888-7777" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Só quero uma cotação de preço para declarar imposto de renda." }
    ],
    score: 0.18,
    status: "not_qualified",
    confidence: "high",
    outcome: "lost"
  },
  # Lead não qualificado — sem orçamento
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 1 a 10" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Sem previsão" },
      { "label" => "Melhor contato", "type": "phone", "value": "(51) 97777-6666" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Não tenho orçamento agora, só pesquisando." }
    ],
    score: 0.24,
    status: "not_qualified",
    confidence: "high",
    outcome: "lost"
  },
  # Lead não classificado (sem respostas relevantes)
  {
    form_fields: [
      { "label" => "Melhor contato", "type": "phone", "value": "(61) 96666-5555" }
    ],
    score: nil,
    status: "unclassified",
    confidence: nil,
    outcome: nil
  },
]

leads_contabil.each_with_index do |attrs, idx|
  lead = contabil_norte.leads.find_by("form_fields = ?::jsonb", attrs[:form_fields].to_json) ||
         contabil_norte.leads.create!(form_fields: attrs[:form_fields])

  answers_snapshot = Qualification::AnswerSanitizer.call(attrs[:form_fields])

  qualification = LeadQualification.find_or_create_by!(lead: lead) do |q|
    q.status = attrs[:status]
    q.score = attrs[:score]
    q.confidence = attrs[:confidence]
    q.model_version = "tev1:4b"
    q.answers_snapshot = answers_snapshot
    q.criteria_snapshot = contabil_norte.qualification_criteria_or_default
    q.error_message = nil
    q.outcome = attrs[:outcome]
    q.evaluated_at = Time.current - (6 - idx).days
  end
end

# ---------------------------------------------------------------------------
# 4. Leads da Tech Solutions (mix de status)
# ---------------------------------------------------------------------------

leads_tech = [
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(11) 95555-4444" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Empresa de tecnologia precisa de software de gestão. contato@techsolutions.com.br" }
    ],
    score: 0.85,
    status: "qualified",
    confidence: "high",
    outcome: nil
  },
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 1 a 10" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 60 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(11) 94444-3333" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Pequena empresa, só queremos saber preço." }
    ],
    score: 0.31,
    status: "not_qualified",
    confidence: "high",
    outcome: nil
  },
  {
    form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 51 a 200" },
      { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 90 dias" },
      { "label" => "Melhor contato", "type": "phone", "value": "(11) 93333-2222" },
      { "label" => "Conte sua necessidade", "type": "textarea", "value": "Precisamos de ERP para gestão de estoque e financeiro." }
    ],
    score: 0.67,
    status: "qualified",
    confidence: "medium",
    outcome: nil
  },
]

leads_tech.each_with_index do |attrs, idx|
  lead = tech_solutions.leads.find_by("form_fields = ?::jsonb", attrs[:form_fields].to_json) ||
         tech_solutions.leads.create!(form_fields: attrs[:form_fields])

  answers_snapshot = Qualification::AnswerSanitizer.call(attrs[:form_fields])

  LeadQualification.find_or_create_by!(lead: lead) do |q|
    q.status = attrs[:status]
    q.score = attrs[:score]
    q.confidence = attrs[:confidence]
    q.model_version = "tev1:4b"
    q.answers_snapshot = answers_snapshot
    q.criteria_snapshot = tech_solutions.qualification_criteria_or_default
    q.error_message = nil
    q.outcome = attrs[:outcome]
    q.evaluated_at = Time.current - (4 - idx).days
  end
end

# ---------------------------------------------------------------------------
# 5. Leads pendentes (sem qualificação ainda — para testar o botão "Qualificar")
# ---------------------------------------------------------------------------

lead_pendente_fields = [
  { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
  { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" },
  { "label" => "Melhor contato", "type" => "phone", "value" => "(11) 91111-2222" },
  { "label" => "Conte sua necessidade", "type" => "textarea", "value" => "Quero contratar contabilidade urgentemente." }
]

lead_pendente = contabil_norte.leads.find_by("form_fields = ?::jsonb", lead_pendente_fields.to_json) ||
                contabil_norte.leads.create!(form_fields: lead_pendente_fields)

lead_demo_fields = [
  { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 1 a 10" },
  { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" }
]

lead_demo = demo_empresa.leads.find_by("form_fields = ?::jsonb", lead_demo_fields.to_json) ||
            demo_empresa.leads.create!(form_fields: lead_demo_fields)

# ---------------------------------------------------------------------------
# 6. Ativar feature flag para as empresas reais
# ---------------------------------------------------------------------------

Flipper.enable_actor(:lead_qualification, contabil_norte)
Flipper.enable_actor(:lead_qualification, tech_solutions)

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------

puts "   Leads criados: #{Lead.count}"
puts "   Conjuntos de campos: #{FieldSet.count}"
puts "   Qualificações criadas: #{LeadQualification.count}"
puts "   Qualificados: #{LeadQualification.where(status: 'qualified').count}"
puts "   Não qualificados: #{LeadQualification.where(status: 'not_qualified').count}"
puts "   Não classificados: #{LeadQualification.where(status: 'unclassified').count}"
puts "   Pendentes (sem qualificação): #{Lead.left_joins(:lead_qualification).where(lead_qualifications: { id: nil }).count}"
puts ""
puts "✅ Seeds concluídos com sucesso!"
puts ""
puts "Acesse: http://localhost:3000/"
puts "   - Dashboard: /dashboard"
puts "   - Empresas: /companies"
puts "   - Leads: /leads"
puts "   - Qualificações: /lead_qualifications"
