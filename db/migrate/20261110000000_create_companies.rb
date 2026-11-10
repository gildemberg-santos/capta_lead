class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.boolean :demo, null: false, default: false
      t.jsonb :qualification_criteria, null: false, default: {}
      t.timestamps
    end

    add_index :companies, :name, unique: true
  end
end
