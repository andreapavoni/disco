defmodule Disco.Mocks do
  @moduledoc false

  Mox.defmock(Disco.EventStore.ClientMock, for: Disco.EventStore.Client)
end
