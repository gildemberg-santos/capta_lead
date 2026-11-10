# frozen_string_literal: true

FactoryBot.define do
  factory :lead do
    company
    form_fields do
      [
        { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
        { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" },
        { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" },
        { "label" => "Conte sua necessidade", "type" => "textarea", "value" => "Preciso de contabilidade para minha empresa." }
      ]
    end

    trait :com_funcionarios do
      form_fields do
        [
          { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" },
          { "label" => "Quando pretende contratar?", "type" => "select", "value" => "Nos próximos 30 dias" }
        ]
      end
    end

    trait :sem_respostas_relevantes do
      form_fields do
        [
          { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" }
        ]
      end
    end
  end
end
