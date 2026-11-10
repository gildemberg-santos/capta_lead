class LeadQualification < ApplicationRecord
  belongs_to :lead

  enum :status, {
    pending: "pending",
    qualified: "qualified",
    not_qualified: "not_qualified",
    unclassified: "unclassified"
  }, prefix: :status
end
