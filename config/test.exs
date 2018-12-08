# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :disco, Disco.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "disco_test",
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOSTNAME"),
  pool: Ecto.Adapters.SQL.Sandbox
