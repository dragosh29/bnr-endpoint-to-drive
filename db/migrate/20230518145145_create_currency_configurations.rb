class CreateCurrencyConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :currency_configurations do |t| #create the currency_configurations table in the db
      t.string :currency_name
      t.boolean :enabled

      t.timestamps
    end
  end
end
