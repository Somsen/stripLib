class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.references :campaign
      t.string :file, null: false
      t.integer :image_type, null: false

      t.timestamps null: false
    end
    add_index(:images, :image_type)
    add_index(:images, :campaign_id)
  end
end
