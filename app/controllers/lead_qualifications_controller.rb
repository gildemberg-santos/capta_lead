class LeadQualificationsController < ApplicationController
  def index
    @qualifications = LeadQualification
                      .includes(lead: :company)
                      .order(created_at: :desc)
  end

  def show
    @qualification = LeadQualification.includes(lead: :company).find(params[:id])
  end
end
