# frozen_string_literal: true

module Qualification
  class Evaluator
    def initialize(lead, client: OllamaClient.new)
      @lead = lead
      @client = client
    end

    def call
      criteria = @lead.company.qualification_criteria_or_default
      answers = AnswerSanitizer.call(@lead.form_fields)

      return save(status: "unclassified", error_message: "sem respostas relevantes", answers:, criteria:) if answers.empty?

      result = @client.call(answers:, criteria:)
      verdict = Interpreter.call(result[:probability], threshold: criteria["threshold"].to_f)

      save(status: verdict.status, confidence: verdict.confidence, score: result[:probability],
           model_version: result[:model], answers:, criteria:)
    rescue OllamaClient::InvalidResponse => e
      save(status: "unclassified", error_message: e.message, answers:, criteria:)
    end

    private

    def save(status:, answers:, criteria:, score: nil, confidence: nil, model_version: nil, error_message: nil)
      LeadQualification.upsert(
        {
          lead_id: @lead.id,
          status:,
          score:,
          confidence:,
          model_version:,
          error_message:,
          answers_snapshot: answers || {},
          criteria_snapshot: criteria || {},
          evaluated_at: Time.current
        },
        unique_by: :lead_id
      )
    end
  end
end
