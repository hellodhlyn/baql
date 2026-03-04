class RenameEventShopResourcesToDeprecatedEventShopResources < ActiveRecord::Migration[8.0]
  def change
    rename_table :event_shop_resources, :deprecated_event_shop_resources
  end
end
