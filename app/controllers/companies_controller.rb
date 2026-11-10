class CompaniesController < ApplicationController
  def index
    @companies = Company.order(:name).all
  end

  def show
    @company = Company.find(params[:id])
    @leads = @company.leads.order(created_at: :desc)
    @qualifications = @company.lead_qualifications.includes(:lead).order(created_at: :desc)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to companies_path, notice: "Empresa criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @company = Company.find(params[:id])
  end

  def update
    @company = Company.find(params[:id])
    if @company.update(company_params)
      redirect_to company_path(@company), notice: "Empresa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    redirect_to companies_path, notice: "Empresa removida com sucesso."
  end

  private

  def company_params
    params.require(:company).permit(:name, :demo, qualification_criteria: {})
  end
end
