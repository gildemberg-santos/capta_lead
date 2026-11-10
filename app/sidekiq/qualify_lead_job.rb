# frozen_string_literal: true

class QualifyLeadJob
  include Sidekiq::Job

  sidekiq_options queue: "low", retry: 3

  sidekiq_retries_exhausted do |job, _exception|
    LeadQualification.where(lead_id: job["args"].first).update_all(
      status: "unclassified",
      score: nil,
      confidence: nil,
      error_message: "serviço de inferência indisponível",
      evaluated_at: Time.current
    )
  end

  def perform(lead_id)
    lead = Lead.find_by(id: lead_id)
    return unless lead

    Qualification::Evaluator.new(lead).call
  end
end
