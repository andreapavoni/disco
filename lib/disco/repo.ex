defmodule Disco.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :disco, adapter: Ecto.Adapters.Postgres
end
