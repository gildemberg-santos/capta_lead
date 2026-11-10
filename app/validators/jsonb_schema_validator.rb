class JsonbSchemaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    # Se for hash vazio, não validar (será preenchido com defaults)
    return if value.is_a?(Hash) && value.empty?

    unless value.is_a?(Hash)
      record.errors.add(attribute, "deve ser um objeto JSON válido")
      return
    end

    required_keys = %w[instructions qualified not_qualified threshold]
    missing_keys = required_keys - value.keys

    if missing_keys.any?
      record.errors.add(attribute, "está faltando os campos obrigatórios: #{missing_keys.join(', ')}")
    end

    threshold = value["threshold"]
    if threshold.present? && (!threshold.is_a?(Numeric) || threshold < 0 || threshold > 1)
      record.errors.add(attribute, "o threshold deve ser um número entre 0 e 1")
    end
  end
end
