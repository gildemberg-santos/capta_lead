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
end
