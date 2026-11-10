class DashboardController < ApplicationController
  helper_method :qualified_pct, :not_qualified_pct, :unclassified_pct, :pending_pct

  def index
    @companies_count = Company.count
    @leads_count = Lead.count
    @qualifications_count = LeadQualification.count
    @pending_count = LeadQualification.where(status: "pending").count
    @qualified_count = LeadQualification.where(status: "qualified").count
    @not_qualified_count = LeadQualification.where(status: "not_qualified").count
    @unclassified_count = LeadQualification.where(status: "unclassified").count

    rows = LeadQualification
           .where.not(outcome: nil)
           .where.not(score: nil)
           .pluck(:score, :status, :outcome)
           .map do |score, status, outcome|
             { score: score.to_f, predicted: status == "qualified", actual: outcome == "won" }
           end

    @metrics = Qualification::Metrics.call(rows)
    @calibration = @metrics[:calibracao] || []
  end

  private

  def total_qualified
    @total_qualified ||= [@qualified_count, @not_qualified_count, @unclassified_count, @pending_count].sum
  end

  def qualified_pct
    return 0 if total_qualified.zero?
    ((@qualified_count.to_f / total_qualified) * 100).round(1)
  end

  def not_qualified_pct
    return 0 if total_qualified.zero?
    ((@not_qualified_count.to_f / total_qualified) * 100).round(1)
  end

  def unclassified_pct
    return 0 if total_qualified.zero?
    ((@unclassified_count.to_f / total_qualified) * 100).round(1)
  end

  def pending_pct
    return 0 if total_qualified.zero?
    ((@pending_count.to_f / total_qualified) * 100).round(1)
  end
end
