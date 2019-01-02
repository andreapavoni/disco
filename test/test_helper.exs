{:ok, _} = Disco.Application.start(:ok, :ok)
ExUnit.start(exclude: [:skip])
{:ok, _} = Application.ensure_all_started(:ex_machina)
