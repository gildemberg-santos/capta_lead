# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FieldSets", type: :request do
  let(:company) { create(:company) }

  describe "GET /companies/:id" do
    it "lista os conjuntos de campos da empresa" do
      create(:field_set, company: company, name: "Padrão")

      get company_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Conjuntos de Campos")
      expect(response.body).to include("Padrão")
    end
  end

  describe "POST /companies/:company_id/field_sets" do
    it "cria um conjunto de campos para a empresa" do
      expect do
        post company_field_sets_path(company), params: {
          field_set: {
            name: "Padrão",
            fields_json: '[{"label":"Cidade","type":"text"}]'
          }
        }
      end.to change(company.field_sets, :count).by(1)

      expect(response).to redirect_to(company_path(company))
      expect(company.field_sets.last.fields).to eq([{ "label" => "Cidade", "type" => "text" }])
    end

    it "rejeita JSON inválido" do
      expect do
        post company_field_sets_path(company), params: {
          field_set: { name: "Padrão", fields_json: "[{" }
        }
      end.not_to change(FieldSet, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /companies/:company_id/field_sets/:id" do
    it "remove o conjunto da empresa" do
      field_set = create(:field_set, company: company)

      expect do
        delete company_field_set_path(company, field_set)
      end.to change(company.field_sets, :count).by(-1)

      expect(response).to redirect_to(company_path(company))
    end
  end
end
