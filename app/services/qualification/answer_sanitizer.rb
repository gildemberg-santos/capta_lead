# frozen_string_literal: true

module Qualification
  class AnswerSanitizer
    PERSONAL_TYPES = %w[name email phone whatsapp cpf cnpj address password].freeze

    PATTERNS = {
      email: /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/,
      cnpj: %r{\b\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}\b},
      cpf: /\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/,
      phone: /(?:\+?55\s?)?\(?\b\d{2}\)?\s?9?\d{4}[-\s]?\d{4}\b/
    }.freeze

    # fields: [{ "label" => "...", "type" => "...", "value" => "..." }]
    def self.call(fields)
      fields
        .reject { |field| field["value"].to_s.strip.empty? || PERSONAL_TYPES.include?(field["type"]) }
        .to_h { |field| [field["label"], mask(field["value"].to_s.strip)] }
    end

    def self.mask(text)
      PATTERNS.reduce(text) { |acc, (kind, regex)| acc.gsub(regex, "[#{kind}_removido]") }
    end
  end
end
