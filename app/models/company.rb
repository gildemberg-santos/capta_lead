class Company < ApplicationRecord
  include Flipper::Identifier

  has_many :leads, dependent: :destroy
  has_many :lead_qualifications, through: :leads

  DEFAULT_CRITERIA = {
    "instructions" => "Este lead é qualificado para comprar o produto ou serviço da empresa?",
    "qualified" => "Porte e orçamento compatíveis, decisor ou influenciador, necessidade clara e urgência real.",
    "not_qualified" => "Sem orçamento, sem poder de decisão, sem necessidade clara ou sem prazo.",
    "threshold" => 0.5
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :qualification_criteria, jsonb_schema: true, allow_nil: true

  before_validation :normalize_threshold

  def qualification_criteria_or_default
    DEFAULT_CRITERIA.merge(qualification_criteria.presence || {})
  end

  def criteria_instructions
    qualification_criteria_or_default["instructions"]
  end

  def criteria_qualified
    qualification_criteria_or_default["qualified"]
  end

  def criteria_not_qualified
    qualification_criteria_or_default["not_qualified"]
  end

  def criteria_threshold
    qualification_criteria_or_default["threshold"].to_f
  end

  private

  def normalize_threshold
    return if qualification_criteria.blank?

    threshold = qualification_criteria["threshold"]
    return if threshold.blank?

    # Se o threshold estiver entre 1 e 10, assume que veio em escala 0-10 e converte para 0-1
    if threshold.is_a?(Numeric) && threshold >= 1 && threshold <= 10
      qualification_criteria["threshold"] = threshold / 10.0
    end
  end
end
