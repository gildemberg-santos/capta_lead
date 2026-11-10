# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::Evaluator do
  let(:company) { create(:company) }
  let(:lead) do
    create(:lead, company: company, form_fields: [
      { "label" => "Quantos funcionários?", "type" => "select", "value" => "De 11 a 50" }
    ])
  end
  let(:client) { instance_double(Qualification::OllamaClient) }

  it "grava a classificação quando o modelo responde" do
    allow(client).to receive(:call).and_return(probability: 0.82, model: "tev1:4b")

    described_class.new(lead, client:).call

    expect(lead.reload.lead_qualification)
      .to have_attributes(status: "qualified", confidence: "high", model_version: "tev1:4b")
  end

  it "fica sem classificação quando a resposta é inválida" do
    allow(client).to receive(:call)
      .and_raise(Qualification::OllamaClient::InvalidResponse, "fora do intervalo: 1.7")

    described_class.new(lead, client:).call

    expect(lead.reload.lead_qualification).to have_attributes(status: "unclassified", score: nil)
  end

  it "deixa erro transitório subir para o Sidekiq tentar de novo" do
    allow(client).to receive(:call).and_raise(Qualification::OllamaClient::TransientError)

    expect { described_class.new(lead, client:).call }
      .to raise_error(Qualification::OllamaClient::TransientError)
  end

  it "marca como sem classificação quando não há respostas relevantes" do
    lead = create(:lead, company: company, form_fields: [
      { "label" => "Melhor contato", "type" => "phone", "value" => "(85) 99999-0000" }
    ])

    described_class.new(lead, client:).call

    expect(lead.reload.lead_qualification).to have_attributes(
      status: "unclassified",
      error_message: "sem respostas relevantes"
    )
  end

  it "usa o limiar personalizado da empresa" do
    company.update!(qualification_criteria: {
      "instructions" => "Este lead é qualificado?",
      "qualified" => "Porte compatível",
      "not_qualified" => "Sem porte",
      "threshold" => 0.8
    })
    allow(client).to receive(:call).and_return(probability: 0.6, model: "tev1:4b")

    described_class.new(lead, client:).call

    expect(lead.reload.lead_qualification).to have_attributes(status: "not_qualified")
  end
end
