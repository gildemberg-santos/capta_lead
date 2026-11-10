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

    # Reprocessa qualquer qualificacao existente.
    # Volta o status para pending e re-enfileira o job.
    def self.reprocess!(lead)
      return if lead.demo?
      return unless Flipper.enabled?(:lead_qualification, lead.company)

      qualification = LeadQualification.find_by(lead_id: lead.id)
      return nil unless qualification

      qualification.update!(status: "pending", error_message: nil)
      QualifyLeadJob.perform_async(lead.id)
    rescue StandardError => e
      Rails.logger.error("[qualificacao] falha ao reprocessar lead #{lead.id}: #{e.message}")
      nil
    end
  end
end
