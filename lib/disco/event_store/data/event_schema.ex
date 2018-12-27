defmodule Disco.EventStore.Data.EventSchema do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @type t :: %__MODULE__{}
  @type event :: %{:__struct__ => atom(), optional(atom()) => any()}

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "event_store" do
    field(:aggregate_id, :binary_id)
    field(:offset, :integer)
    field(:emitted_at, :utc_datetime)
    field(:type, :string)
    field(:payload, Disco.EventStore.Ecto.PayloadType)
    field(:payload_json, :map)

    timestamps()
  end

  @required_fields ~w(id type emitted_at)a
  @optional_fields ~w(payload payload_json aggregate_id)a

  @spec changeset_event(Disco.Event.t()) :: Ecto.Changeset.t()
  def changeset_event(%Disco.Event{} = event) do
    cast(%__MODULE__{}, Map.from_struct(event), @required_fields ++ @optional_fields)
  end

  @spec all :: Ecto.Query.t()
  def all do
    from(u in __MODULE__, order_by: [desc: u.emitted_at])
  end

  @spec with_aggregate_id(String.t()) :: Ecto.Query.t()
  def with_aggregate_id(nil), do: __MODULE__

  def with_aggregate_id(aggregate_id) do
    from(e in __MODULE__, where: e.aggregate_id == ^aggregate_id)
  end

  @spec with_types([String.t()]) :: Ecto.Query.t()
  def with_types(types) do
    from(e in __MODULE__, where: e.type in ^types)
  end

  @spec after_offset(__MODULE__ | Ecto.Query.t(), integer) :: Ecto.Query.t()
  def after_offset(events \\ __MODULE__, offset) do
    from(e in events, where: e.offset > ^offset, order_by: e.offset)
  end
end
