defmodule Disco.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = child_apps(Mix.env())

    opts = [strategy: :one_for_one, name: Disco.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp child_apps(:test) do
    [
      Disco.Repo
    ]
  end

  defp child_apps(_), do: []
end
