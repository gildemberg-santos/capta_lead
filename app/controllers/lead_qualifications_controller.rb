# frozen_string_literal: true

# Controller responsável pela listagem e detalhe das qualificações de leads geradas pela IA.
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
