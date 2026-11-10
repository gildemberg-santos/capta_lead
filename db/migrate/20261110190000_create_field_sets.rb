class CreateFieldSets < ActiveRecord::Migration[7.1]
  def change
    create_table :field_sets do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.jsonb :fields, null: false, default: []

      t.timestamps
    end

    add_index :field_sets, [ :company_id, :name ], unique: true
  end
end
