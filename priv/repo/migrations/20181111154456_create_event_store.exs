defmodule Disco.Repo.Migrations.CreateEventStore do
  use Ecto.Migration

  def change do
    create table(:event_store, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:aggregate_id, :uuid, default: nil)
      add(:offset, :serial, null: false)
      add(:emitted_at, :utc_datetime, null: false)
      add(:type, :string, null: false)
      add(:payload, :binary)
      add(:payload_json, :map)

      timestamps()
    end
  end
end
