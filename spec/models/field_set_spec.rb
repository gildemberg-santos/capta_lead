# frozen_string_literal: true

require "rails_helper"

RSpec.describe FieldSet do
  subject(:field_set) { build(:field_set) }

  describe "associações" do
    it "pertence a uma empresa" do
      company = create(:company)
      field_set.company = company

      expect(field_set.save).to be(true)
      expect(field_set.reload.company).to eq(company)
    end
  end

  describe "validações" do
    it "é válido com name e fields" do
      expect(field_set).to be_valid
    end

    it "exige name" do
      field_set.name = ""
      expect(field_set).not_to be_valid
      expect(field_set.errors[:name]).to include("can't be blank")
    end

    it "exige name único por empresa" do
      company = create(:company)
      create(:field_set, company: company, name: "Padrão")

      duplicate = build(:field_set, company: company, name: "Padrão")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "permite o mesmo nome em empresas diferentes" do
      create(:field_set, company: create(:company), name: "Padrão")

      another = build(:field_set, company: create(:company), name: "Padrão")
      expect(another).to be_valid
    end

    it "rejeita fields que não é array" do
      field_set.fields = { "label" => "X", "type" => "text" }
      expect(field_set).not_to be_valid
      expect(field_set.errors[:fields]).to include("deve ser um array JSON")
    end

    it "rejeita campo sem label ou type" do
      field_set.fields = [{ "label" => "Só label" }, { "type" => "text" }]
      expect(field_set).not_to be_valid
      expect(field_set.errors[:fields].size).to eq(2)
    end

    it "rejeita tipo de campo desconhecido" do
      field_set.fields = [{ "label" => "Campo", "type" => "inexistente" }]
      expect(field_set).not_to be_valid
      expect(field_set.errors[:fields]).to include("campo 1 tem tipo inválido")
    end

    it "aceita array vazio" do
      field_set.fields = []
      expect(field_set).to be_valid
    end
  end

  describe "#fields_json" do
    it "serializa os fields em JSON legível" do
      expect(JSON.parse(field_set.fields_json)).to eq(field_set.fields)
    end

    it "aceita JSON válido no setter" do
      field_set.fields_json = '[{"label":"Cidade","type":"text"}]'

      expect(field_set.fields).to eq([{ "label" => "Cidade", "type" => "text" }])
      expect(field_set).to be_valid
    end

    it "limpa os fields quando o valor é blank" do
      field_set.fields_json = ""

      expect(field_set.fields).to eq([])
    end

    it "adiciona erro no campo quando o JSON é inválido" do
      field_set.fields_json = "[{"

      expect(field_set).not_to be_valid
      expect(field_set.errors[:fields_json]).to include("deve ser um JSON válido")
    end

    it "preserva o valor digitado quando o JSON é inválido" do
      field_set.fields_json = "[{"

      expect(field_set.fields_json).to eq("[{")
    end
  end

  describe "#labels" do
    it "retorna os labels dos campos" do
      field_set.fields = [
        { "label" => "Quantos funcionários?", "type" => "select" },
        { "label" => "Melhor contato", "type" => "phone" }
      ]

      expect(field_set.labels).to eq(["Quantos funcionários?", "Melhor contato"])
    end

    it "ignora labels ausentes" do
      field_set.fields = [{ "type" => "text" }, { "label" => "Cidade", "type" => "text" }]

      expect(field_set.labels).to eq(["Cidade"])
    end
  end
end
