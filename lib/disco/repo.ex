defmodule Disco.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: Application.get_env(:disco, :otp_app, :disco),
    adapter: Ecto.Adapters.Postgres
end
