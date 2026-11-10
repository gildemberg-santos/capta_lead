class CreateLeadQualifications < ActiveRecord::Migration[7.1]
  def change
    create_table :lead_qualifications do |t|
      t.references :lead, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.decimal :score, precision: 4, scale: 3
      t.string :confidence
      t.string :model_version
      t.jsonb :answers_snapshot, null: false, default: {}
      t.jsonb :criteria_snapshot, null: false, default: {}
      t.string :error_message
      t.string :outcome # "won" ou "lost", preenchido pelo time comercial
      t.datetime :evaluated_at
      t.timestamps
    end
  end
end
