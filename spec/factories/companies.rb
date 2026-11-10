# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Empresa #{n}" }
    demo { false }
    qualification_criteria { {} }

    trait :contabil_norte do
      name { "Contábil Norte" }
      qualification_criteria do
        {
          "instructions" => "Este lead é qualificado para comprar o produto ou serviço da empresa?",
          "qualified" => "Empresa com 5 ou mais funcionários, faturamento acima de R$ 50 mil/mês e contratação em até 60 dias.",
          "not_qualified" => "MEI sem funcionários, quem só quer cotação de preço ou sem previsão de contratação.",
          "threshold" => 0.5
        }
      end
    end

    trait :demo do
      demo { true }
    end
  end
end
