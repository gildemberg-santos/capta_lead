class AddQualificationCriteriaToCompanies < ActiveRecord::Migration[7.1]
  def change
    # A coluna já foi criada na migration 000000. Este arquivo é mantido
    # para documentar a intenção: qualification_criteria é jsonb na companies.
    # Não há alteração a aplicar se a migration 000000 já rodou.
  end
end
