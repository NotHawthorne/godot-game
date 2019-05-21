class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :handle
      t.string :crypted_password
      t.string :string
      t.string :salt

      t.timestamps
    end
  end
end
