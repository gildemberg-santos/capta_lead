class CreateLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :leads do |t|
      t.references :company, null: false, foreign_key: true
      t.jsonb :form_fields, null: false, default: {}
      t.timestamps
    end

  end
end
