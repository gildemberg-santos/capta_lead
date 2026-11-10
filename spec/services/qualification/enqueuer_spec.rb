# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qualification::Enqueuer do
  let(:company) { create(:company) }
  let(:lead) { create(:lead, company: company) }

  before do
    allow(Flipper).to receive(:enabled?).with(:lead_qualification, company).and_return(true)
  end

  it "nao enfileira lead de demonstracao" do
    demo_lead = create(:lead, company: create(:company, :demo))

    expect { described_class.call(demo_lead) }.not_to change { LeadQualification.count }
  end

  it "nao enfileira quando feature flag esta desligada" do
    allow(Flipper).to receive(:enabled?).with(:lead_qualification, company).and_return(false)

    expect { described_class.call(lead) }.not_to change { LeadQualification.count }
  end

  it "nao enfileira quando ja existe qualificacao para o lead" do
    create(:lead_qualification, lead:)

    expect { described_class.call(lead) }.not_to change { LeadQualification.count }
  end

  it "cria qualificacao pendente e enfileira o job" do
    expect(QualifyLeadJob).to receive(:perform_async).with(lead.id)

    described_class.call(lead)

    expect(lead.reload.lead_qualification).to have_attributes(status: "pending")
  end

  it "registra erro sem derrubar quando falha inesperada" do
    allow(LeadQualification).to receive(:create!).and_raise(StandardError, "banco fora do ar")

    expect(Rails.logger).to receive(:error).with(/falha ao enfileirar lead/)
    expect { described_class.call(lead) }.not_to raise_error
  end

  describe ".reprocess!" do
    it "esta definido na classe Enqueuer" do
      expect(described_class).to respond_to(:reprocess!)
    end

    it "volta qualquer qualificacao para pending e re-enfileira o job" do
      qualification = create(:lead_qualification, lead:, status: "qualified", score: 0.9)

      expect(QualifyLeadJob).to receive(:perform_async).with(lead.id)

      described_class.reprocess!(lead)

      expect(qualification.reload).to have_attributes(status: "pending", error_message: nil)
    end

    it "reprocessa qualificacao com erro" do
      qualification = create(:lead_qualification, lead:, status: "failed", error_message: "serviço indisponível")

      expect(QualifyLeadJob).to receive(:perform_async).with(lead.id)

      described_class.reprocess!(lead)

      expect(qualification.reload).to have_attributes(status: "pending", error_message: nil)
    end

    it "retorna nil quando nao existe qualificacao" do
      expect(described_class.reprocess!(lead)).to be_nil
    end

    it "nao reprocessa lead de demonstracao" do
      demo_lead = create(:lead, company: create(:company, :demo))
      create(:lead_qualification, lead: demo_lead, status: "failed")

      expect(QualifyLeadJob).not_to receive(:perform_async)

      expect(described_class.reprocess!(demo_lead)).to be_nil
    end

    it "nao reprocessa quando feature flag esta desligada" do
      qualification = create(:lead_qualification, lead:, status: "failed")
      allow(Flipper).to receive(:enabled?).with(:lead_qualification, company).and_return(false)

      expect(QualifyLeadJob).not_to receive(:perform_async)

      expect(described_class.reprocess!(lead)).to be_nil
      expect(qualification.reload.status).to eq("failed")
    end

    it "registra erro sem derrubar quando falha inesperada" do
      create(:lead_qualification, lead:, status: "failed")
      allow_any_instance_of(LeadQualification).to receive(:update!).and_raise(StandardError, "banco fora do ar")

      expect(Rails.logger).to receive(:error).with(/falha ao reprocessar lead/)
      expect { described_class.reprocess!(lead) }.not_to raise_error
    end
  end
end
