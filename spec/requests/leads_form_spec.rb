# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Formulário de lead", type: :request do
  it "renderiza o seletor de conjuntos de campos no novo lead" do
    company = create(:company)
    create(:field_set, company: company, name: "Padrão")

    get new_lead_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("field-sets-picker")
    expect(response.body).to include("Padrão")
  end

  it "renderiza o seletor de conjuntos ao editar um lead" do
    lead = create(:lead)
    create(:field_set, company: lead.company, name: "Contato rápido")

    get edit_lead_path(lead)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("field-set-select")
    expect(response.body).to include("Contato rápido")
  end
end
