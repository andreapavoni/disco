defmodule Disco.Repo.Migrations.CreateEventConsumers do
  use Ecto.Migration

  def change do
    create table(:event_consumers) do
      add(:name, :string, null: false)
      add(:offset, :integer, default: 0)
    end

    create(index(:event_consumers, [:name]))
  end
end
