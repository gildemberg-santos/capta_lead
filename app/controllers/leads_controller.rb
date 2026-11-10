class LeadsController < ApplicationController
  def index
    @leads = Lead.includes(:company, :lead_qualification).order(created_at: :desc)
  end

  def show
    @lead = Lead.includes(:company, :lead_qualification).find(params[:id])
  end

  def new
    @lead = Lead.new
    @companies = Company.order(:name)
  end

  def create
    @lead = Lead.new(lead_params_with_fields)
    if @lead.save
      redirect_to leads_path, notice: "Lead criado com sucesso."
    else
      @companies = Company.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @lead = Lead.find(params[:id])
    @companies = Company.order(:name)
  end

  def update
    @lead = Lead.find(params[:id])
    if @lead.update(lead_params_with_fields)
      redirect_to lead_path(@lead), notice: "Lead atualizado com sucesso."
    else
      @companies = Company.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lead = Lead.find(params[:id])
    @lead.destroy
    redirect_to leads_path, notice: "Lead removido com sucesso."
  end

  def qualify
    @lead = Lead.find(params[:id])

    enfileirado = Qualification::Enqueuer.call(@lead)

    if enfileirado
      redirect_to lead_path(@lead), notice: "Qualificação enfileirada com sucesso. Aguarde o processamento."
    else
      redirect_to lead_path(@lead), alert: "Não foi possível enfileirar a qualificação deste lead. Verifique se ele não é de demonstração, se o recurso está ativado para a empresa ou se já não foi qualificado anteriormente."
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:company_id, form_fields_attributes: [:id, :label, :type, :value, :_destroy])
  end

  # Converte os parâmetros aninhados do formulário dinâmico em um array JSON para salvar no jsonb
  def build_form_fields_array(attributes)
    return [] if attributes.blank?

    attributes.values
      .reject { |f| f["_destroy"] == "1" || f["_destroy"] == true }
      .map do |field|
        {
          "label" => field["label"].to_s.strip,
          "type" => field["type"].to_s.strip,
          "value" => field["value"].to_s.strip
        }
      end
      .reject { |f| f["label"].blank? && f["value"].blank? }
  end

  def lead_params_with_fields
    params = lead_params
    if params[:form_fields_attributes]
      params = params.except(:form_fields_attributes)
      params[:form_fields] = build_form_fields_array(params[:form_fields_attributes])
    end
    params
  end
end
