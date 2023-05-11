defmodule Landlord.Repo.Migrations.AddDataSpaceSubscriptions do
  use Ecto.Migration

  def up do
    alter table(:data_spaces) do
      add :description, :string, null: true
      add :picture, :string, null: true
      add :is_active, :boolean, default: false
    end

    execute "UPDATE data_spaces SET is_active = true"

    create table(:subscriptions, primary_key: false) do
      add :subscription_id, :string, primary_key: true
      add :cancel_url, :string
      add :checkout_id, :string
      add :email, :string
      add :next_bill_date, :date
      add :quantity, :integer
      add :status, :string, null: false
      add :subscription_plan_id, :string
      add :update_url, :string
      add :valid_to, :date

      add :data_space_id, references(:data_spaces, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end
  end

  def down do
    drop table(:subscriptions)

    alter table(:data_spaces) do
      remove :is_active
      remove :picture
      remove :description
    end
  end
end
