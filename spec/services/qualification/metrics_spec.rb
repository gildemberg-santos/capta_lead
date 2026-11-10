# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::Metrics do
  describe ".call" do
    it "calcula matriz de confusão e métricas derivadas" do
      rows = [
        { predicted: true, actual: true, score: 0.9 },   # vp
        { predicted: true, actual: false, score: 0.7 },  # fp
        { predicted: false, actual: true, score: 0.3 },  # fn
        { predicted: false, actual: false, score: 0.1 }  # vn
      ]

      result = described_class.call(rows)

      expect(result[:matriz]).to eq(vp: 1, fp: 1, fn: 1, vn: 1)
      expect(result[:acuracia]).to eq(0.5)
      expect(result[:precisao]).to eq(0.5)
      expect(result[:recall]).to eq(0.5)
    end

    it "retorna nil quando denominador é zero" do
      rows = []

      result = described_class.call(rows)

      expect(result[:acuracia]).to be_nil
      expect(result[:precisao]).to be_nil
      expect(result[:recall]).to be_nil
      expect(result[:brier]).to be_nil
      expect(result[:calibracao]).to eq([])
    end

    it "calcula Brier score" do
      rows = [
        { predicted: true, actual: true, score: 0.8 },
        { predicted: false, actual: false, score: 0.2 }
      ]

      result = described_class.call(rows)
      # ((0.8 - 1)**2 + (0.2 - 0)**2) / 2 = (0.04 + 0.04) / 2 = 0.04
      expect(result[:brier]).to eq(0.04)
    end

    it "agrupa calibração em faixas" do
      rows = [
        { predicted: false, actual: false, score: 0.1 },
        { predicted: false, actual: false, score: 0.15 },
        { predicted: true, actual: true, score: 0.9 },
        { predicted: true, actual: false, score: 0.85 }
      ]

      result = described_class.call(rows)

      expect(result[:calibracao].size).to be >= 1
      faixa_baixa = result[:calibracao].find { |c| c[:faixa] == "0.0–0.2" }
      expect(faixa_baixa[:leads]).to eq(2)
      expect(faixa_baixa[:nota_media]).to eq(0.13)
      expect(faixa_baixa[:conversao_real]).to eq(0.0)
    end
  end
end
