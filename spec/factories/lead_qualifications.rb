# frozen_string_literal: true

FactoryBot.define do
  factory :lead_qualification do
    lead
    status { "pending" }
    score { nil }
    confidence { nil }
    model_version { nil }
    answers_snapshot { {} }
    criteria_snapshot { {} }
    error_message { nil }
    outcome { nil }
    evaluated_at { nil }
  end
end
