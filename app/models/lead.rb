class Lead < ApplicationRecord
  belongs_to :company
  has_one :lead_qualification, dependent: :destroy

  validates :form_fields, presence: true
  validate :form_fields_must_be_valid_json_array

  def demo?
    company.demo?
  end

  # Retorna os campos do formulário como array de hashes
  def form_fields_array
    form_fields.is_a?(Array) ? form_fields : []
  end

  # Busca o valor de um campo pelo label
  def field_value(label)
    field = form_fields_array.find { |f| f["label"] == label }
    field ? field["value"] : nil
  end

  # Campos agrupados por tipo para exibição
  def fields_by_type
    form_fields_array.group_by { |f| f["type"] }
  end

  # Campos que contêm dados pessoais (para exibir aviso LGPD)
  def personal_fields
    personal_types = %w[name email phone whatsapp cpf cnpj address password]
    form_fields_array.select { |f| personal_types.include?(f["type"]) }
  end

  # Campos não pessoais (enviados para o modelo IA)
  def business_fields
    personal_types = %w[name email phone whatsapp cpf cnpj address password]
    form_fields_array.reject { |f| personal_types.include?(f["type"]) || f["value"].to_s.strip.empty? }
  end

  private

  def form_fields_must_be_valid_json_array
    return if form_fields.blank?

    parsed = form_fields.is_a?(String) ? JSON.parse(form_fields) : form_fields

    unless parsed.is_a?(Array)
      errors.add(:form_fields, "deve ser um array JSON")
      return
    end

    parsed.each_with_index do |field, index|
      unless field.is_a?(Hash) && field.key?("label") && field.key?("type") && field.key?("value")
        errors.add(:form_fields, "campo #{index + 1} deve ter label, type e value")
      end
    end
  rescue JSON::ParserError => e
    errors.add(:form_fields, "JSON inválido: #{e.message}")
  end
end
