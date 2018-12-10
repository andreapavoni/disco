defmodule Disco.EventStore.Data.EventConsumer do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t :: %__MODULE__{}

  schema "event_consumers" do
    field(:name, :string)
    field(:offset, :integer, default: 0)
  end

  @fields ~w(name offset)a

  @spec update_offset_changeset(t | nil, String.t(), integer) :: Changeset.t()
  def update_offset_changeset(nil, name, offset) do
    update_offset_changeset(%__MODULE__{}, name, offset)
  end

  def update_offset_changeset(%__MODULE__{} = event_consumer, name, offset) do
    event_consumer
    |> cast(%{"name" => name, "offset" => offset}, @fields)
    |> validate_required(@fields)
  end

  def by_name(event_consumer, name) do
    from(ec in event_consumer, where: ec.name == ^name)
  end
end
