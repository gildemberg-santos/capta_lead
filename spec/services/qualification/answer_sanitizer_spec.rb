# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::AnswerSanitizer do
  it "remove dados pessoais pelo tipo do campo, não pelo rótulo" do
    fields = [
      { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" },
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" }
    ]

    expect(described_class.call(fields)).to eq("Quantos funcionários?" => "De 11 a 50")
  end

  it "mascara dados pessoais digitados em texto livre" do
    fields = [
      { "label" => "Conte sua necessidade", "type" => "textarea",
        "value" => "CPF 123.456.789-09, CNPJ 12.345.678/0001-90" }
    ]

    expect(described_class.call(fields)["Conte sua necessidade"])
      .to eq("CPF [cpf_removido], CNPJ [cnpj_removido]")
  end

  it "ignora campos com valor vazio" do
    fields = [
      { "label" => "Campo vazio", "type" => "text", "value" => "" },
      { "label" => "Campo preenchido", "type" => "text", "value" => "alguma coisa" }
    ]

    expect(described_class.call(fields)).to eq("Campo preenchido" => "alguma coisa")
  end

  it "mascara email em texto livre" do
    fields = [
      { "label" => "Observações", "type" => "textarea", "value" => "me chama no joao@empresa.com" }
    ]

    expect(described_class.call(fields)["Observações"])
      .to eq("me chama no [email_removido]")
  end

  it "ordena CNPJ antes de CPF para não cortar pelo meio" do
    fields = [
      { "label" => "Observações", "type" => "textarea", "value" => "CNPJ 12.345.678/0001-90" }
    ]

    expect(described_class.call(fields)["Observações"])
      .to eq("CNPJ [cnpj_removido]")
  end
end
