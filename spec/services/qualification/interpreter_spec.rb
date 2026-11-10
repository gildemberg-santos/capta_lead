# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::Interpreter do
  it "classifica como qualificado com confiança alta quando nota está acima do limiar" do
    result = described_class.call(0.8, threshold: 0.5)

    expect(result.status).to eq("qualified")
    expect(result.confidence).to eq("high")
  end

  it "classifica como qualificado com confiança baixa quando nota está perto do limiar" do
    result = described_class.call(0.55, threshold: 0.5)

    expect(result.status).to eq("qualified")
    expect(result.confidence).to eq("low")
  end

  it "classifica como não qualificado com confiança alta quando nota está abaixo do limiar" do
    result = described_class.call(0.2, threshold: 0.5)

    expect(result.status).to eq("not_qualified")
    expect(result.confidence).to eq("high")
  end

  it "usa limiar personalizado" do
    result = described_class.call(0.6, threshold: 0.8)

    expect(result.status).to eq("not_qualified")
  end

  it "confiança média quando distância está entre 0.1 e 0.3" do
    result = described_class.call(0.3, threshold: 0.5)

    expect(result.confidence).to eq("medium")
  end
end
