module ApplicationHelper
  def lead_answer(lead, label)
    field = lead.form_fields.find { |f| f["label"] == label }
    field ? field["value"] : "—"
  end

  def criteria_value(key, company = nil)
    company ||= @company
    return Company::DEFAULT_CRITERIA[key] if company.nil? || company.qualification_criteria.blank?

    company.qualification_criteria[key] || Company::DEFAULT_CRITERIA[key]
  end

  def preview_criteria(company = nil)
    company ||= @company
    company&.qualification_criteria_or_default || Company::DEFAULT_CRITERIA
  end
end
