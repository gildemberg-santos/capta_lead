# frozen_string_literal: true

module Qualification
  class Enqueuer
    def self.call(lead)
      return if lead.demo?
      return unless Flipper.enabled?(:lead_qualification, lead.company)
      return if LeadQualification.exists?(lead_id: lead.id)

      LeadQualification.create!(lead:, status: "pending")
      QualifyLeadJob.perform_async(lead.id)
    rescue ActiveRecord::RecordNotUnique
      nil
    rescue StandardError => e
      Rails.logger.error("[qualificacao] falha ao enfileirar lead #{lead.id}: #{e.message}")
    end
  end
end
