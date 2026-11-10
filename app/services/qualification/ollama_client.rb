# frozen_string_literal: true

require "net/http"

module Qualification
  class OllamaClient
    class TransientError < StandardError; end
    class InvalidResponse < StandardError; end

    QUESTION_KEY = "qualificado"

    def initialize(url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"),
                   model: ENV.fetch("QUALIFICATION_MODEL", "tev1:4b"),
                   timeout: Integer(ENV.fetch("OLLAMA_TIMEOUT", "120")))
      @uri = URI.join(url, "/v1/systemone")
      @model = model
      @timeout = timeout
    end

    def call(answers:, criteria:)
      response = Net::HTTP.start(@uri.host, @uri.port, open_timeout: 5, read_timeout: @timeout) do |http|
        http.post(@uri.path, payload(answers, criteria).to_json, "Content-Type" => "application/json")
      end

      raise TransientError, "HTTP #{response.code}" if response.code.to_i >= 500
      raise InvalidResponse, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      noul = JSON.parse(response.body).dig("answers", QUESTION_KEY, "noul")
      { probability: parse_probability(noul), model: @model }
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
      raise TransientError, e.message
    rescue JSON::ParserError => e
      raise InvalidResponse, e.message
    end

    private

    def payload(answers, criteria)
      {
        model: @model,
        state: answers,
        questions: {
          QUESTION_KEY => {
            type: "noul",
            instructions: criteria["instructions"],
            criteria: { "true" => criteria["qualified"], "false" => criteria["not_qualified"] }
          }
        }
      }
    end

    def parse_probability(value)
      raise InvalidResponse, "noul ausente" unless value.is_a?(Numeric)
      raise InvalidResponse, "fora do intervalo: #{value}" unless value.between?(0, 1)

      value.to_f
    end
  end
end
