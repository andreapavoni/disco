# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, :console,
  level: :debug,
  metadata: [:application],
  format: "\n$time $metadata[$level] $levelpad$message\n"

config :disco, Disco.Repo,
  database: "disco_dev",
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOSTNAME"),
  show_sensitive_data_on_connection_error: true
