# frozen_string_literal: true

# Conjunto reutilizável de campos de formulário de uma empresa.
# Os campos guardam apenas label e type; os valores são preenchidos no lead.
class FieldSet < ApplicationRecord
  TYPES = %w[text select phone whatsapp email cpf cnpj address textarea password].freeze

  belongs_to :company

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validate :fields_must_be_valid

  # Getter/Setter usados pelo formulário (textarea JSON).
  def fields_json
    @fields_json_raw || JSON.pretty_generate(fields_array)
  end

  def fields_json=(value)
    @fields_json_raw = value
    @fields_json_invalid = false
    self.fields = value.blank? ? [] : JSON.parse(value)
  rescue JSON::ParserError
    @fields_json_invalid = true
    self.fields = []
  end

  def fields_array
    fields.is_a?(Array) ? fields : []
  end

  def labels
    fields_array.map { |field| field["label"] }.compact
  end

  private

  def fields_must_be_valid
    errors.add(:fields_json, "deve ser um JSON válido") if @fields_json_invalid
    return if fields.blank?

    unless fields.is_a?(Array)
      errors.add(:fields, "deve ser um array JSON")
      return
    end

    fields.each_with_index do |field, index|
      unless field.is_a?(Hash) && field["label"].present? && field["type"].present?
        errors.add(:fields, "campo #{index + 1} deve ter label e type")
        next
      end

      next if TYPES.include?(field["type"])

      errors.add(:fields, "campo #{index + 1} tem tipo inválido")
    end
  end
end
