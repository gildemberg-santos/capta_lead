# frozen_string_literal: true

namespace :qualification do
  desc "Métricas do classificador comparadas com o resultado comercial real"
  task metrics: :environment do
    rows = LeadQualification
           .where.not(outcome: nil)
           .where.not(score: nil)
           .pluck(:score, :status, :outcome)
           .map do |score, status, outcome|
             {
               score: score.to_f,
               predicted: status == "qualified",
               actual: outcome == "won"
             }
           end

    pp Qualification::Metrics.call(rows)
  end
end
