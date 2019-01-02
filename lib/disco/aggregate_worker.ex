defmodule Disco.AggregateWorker do
  @moduledoc """
  Disco aggregate worker.
  """

  use GenServer

  ## Client API

  def start_link(%_{id: nil} = aggregate_module),
    do: start_link(%{aggregate_module | id: UUID.uuid4()})

  def start_link(%aggregate_name{id: id} = aggregate_module) when is_binary(id) do
    GenServer.start_link(__MODULE__, aggregate_module, name: {:global, "#{aggregate_name}:#{id}"})
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

  def child_spec(aggregate) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [aggregate]},
      shutdown: 600_000,
      restart: :transient,
      type: :worker
    }
  end

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
