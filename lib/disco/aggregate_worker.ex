defmodule Disco.AggregateWorker do
  @moduledoc """
  Disco aggregate worker.
  """

  use GenServer

  ## Client API

  def start_link(%_{id: nil} = aggregate_module),
    do: start_link(%{aggregate_module | id: UUID.uuid4()})

  def start_link(%_{id: id} = aggregate_module) when is_binary(id) do
    GenServer.start_link(__MODULE__, aggregate_module)
  end

  def process(events, pid) do
    # TODO: should be a cast?
    GenServer.call(pid, {:process, events})
  end

  def handle(command, pid) do
    # TODO: might be call OR cast
    GenServer.call(pid, {:handle_command, command})
  end

  ## Server callbacks

  @impl true
  def init(%_{id: id} = state) do
    Process.send(self(), {:load_current_state, id}, [])

    {:ok, state}
  end

  @impl true
  def handle_info({:load_current_state, id}, %aggregate_module{} = state) do
    {:ok, state} =
      id
      |> aggregate_module.load_aggregate_events()
      |> do_process(state)

    {:noreply, state}
  end

  @impl true
  def handle_call({:process, events}, _from, state) do
    do_process(events, state)
  end

  @impl true
  def handle_call({:handle_command, %command{} = cmd}, _from, %aggregate_module{} = state) do
    # run cmd and get events
    events = command.run(cmd, state)

    # process events
    {:ok, new_state} = do_process(events, state)

    # commit events to event store
    aggregate_module.commit(events)

    {:reply, events, new_state}
  end

  defp do_process(events, %aggregate_module{} = state) do
    {:ok, Enum.reduce(events, state, &aggregate_module.apply_event(&1, &2))}
  end
end

# FROM event store
# [
#   %{
#     aggregate_id: "51fee371-9263-4f85-b358-6f097b53d328",
#     emitted_at: #DateTime<2018-12-20 13:33:40Z>,
#     id: "e7561681-9ccf-4520-b754-3c971e4d202d",
#     inserted_at: ~N[2018-12-20 13:33:40],
#     offset: 3,
#     payload: %{
#       aggregate_id: "51fee371-9263-4f85-b358-6f097b53d328",
#       balance: 0.0,
#       type: "WalletCreated",
#       user_id: "efcd95a5-b2d3-429c-b14f-baa47822084c"
#     },
#     type: "WalletCreated",
#     updated_at: ~N[2018-12-20 13:33:40]
#   }
# ]

# FROM aggregate
# [
#   %{
#     "aggregate_id" => "51fee371-9263-4f85-b358-6f097b53d328",
#     "emitted_at" => #DateTime<2018-12-20 15:22:38.983181Z>,
#     "id" => "ac647747-6e1f-4761-8efc-f3aca8978c68",
#     "payload" => %{
#       aggregate_id: "51fee371-9263-4f85-b358-6f097b53d328",
#       id: "51fee371-9263-4f85-b358-6f097b53d328",
#       type: "WalletDeleted"
#     },
#     "payload_json" => %{
#       aggregate_id: "51fee371-9263-4f85-b358-6f097b53d328",
#       id: "51fee371-9263-4f85-b358-6f097b53d328",
#       type: "WalletDeleted"
#     },
#     "type" => "WalletDeleted"
#   }
# ]
