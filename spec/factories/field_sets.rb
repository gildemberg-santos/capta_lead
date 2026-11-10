# frozen_string_literal: true

FactoryBot.define do
  factory :field_set do
    company
    sequence(:name) { |n| "Conjunto #{n}" }
    fields do
      [
        { "label" => "Quantos funcionários?", "type" => "select" },
        { "label" => "Melhor contato", "type" => "phone" }
      ]
    end
  end
end
