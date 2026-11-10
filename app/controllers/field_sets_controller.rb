# frozen_string_literal: true

# Gerencia os conjuntos de campos reutilizáveis de uma empresa.
class FieldSetsController < ApplicationController
  before_action :set_company
  before_action :set_field_set, only: %i[edit update destroy]

  def new
    @field_set = @company.field_sets.new
  end

  def create
    @field_set = @company.field_sets.new(field_set_params)

    if @field_set.save
      redirect_to company_path(@company), notice: "Conjunto de campos criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @field_set.update(field_set_params)
      redirect_to company_path(@company), notice: "Conjunto de campos atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @field_set.destroy
    redirect_to company_path(@company), notice: "Conjunto de campos removido com sucesso."
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_field_set
    @field_set = @company.field_sets.find(params[:id])
  end

  def field_set_params
    params.require(:field_set).permit(:name, :fields_json)
  end
end
