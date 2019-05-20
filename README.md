# Disco

Minimal, opinionated yet flexible library to build software based on commands,
queries and events. Not a stricly a CQRS/ES in the known terms, because it's
not always possible to follow 100% CQRS/ES pattern neither anywhere in your
apps. Disco tries to solve this gap.

### Production ready?

Not yet. Well, this approach and part of its code has been used to build several apps in production
without problems, however before being really usable, it might need some polishing. Expect
potential breaking changes until explicitly stated.

## Installation and setup

The package is available in [Hex](https://hex.pm/packages/disco), follow these steps to install:

1.  Add `disco` to your list of dependencies in `mix.exs` in your app (if it's part
    of an umbrella project, add it where needed):

```elixir
def deps do
  # Get from hex
  [{:disco, "~> 0.1.0"}]
  # Or use the latest from master
  [{:disco, github: "andreapavoni/disco"}]
end
```

2.  Configure the event store **only on the app where you want to run it**. That means that
    if you're working on an umbrella project, you have to choose an app in particular. The
    best way is to have an app dedicated to work as event_store.

    * Generate migrations for the database

    ```sh
    mix do deps.get, compile, disco.generate_event_store_migrations
    ```

    * Configure event store repo

    ```elixir
    # config/config.exs

    config :disco, otp_app: :my_app
    config :my_app, ecto_repos: [Disco.Repo]

    config :core, Disco.Repo,
      dadatabase: "my_app_database",
      username: System.get_env("POSTGRES_USER"),
      password: System.get_env("POSTGRES_PASSWORD"),
      hostname: System.get_env("POSTGRES_HOSTNAME")
    ```

3.  Configure the event store client to the app(s) that need to interact with the event store

    * Configure the event store client

    ```elixir
    # config/config.exs

    config :my_app, :event_store_client, MyApp.EventStoreClient
    ```

    * Create a wrapper for the event store client (so that it stays isolated)

    ```elixir
    defmodule MyApp.EventStoreClient do
      use Disco.EventStore.Client
    end
    ```

## Documentation

The documentation is available at [https://hexdocs.pm/disco](https://hexdocs.pm/disco), it
contains almost all the information needed to get started with Disco.

## Usage

Quick and dirty console example, to show how it's supposed to work.

## TODO / Short term roadmap

* [x] improve overall documentation
* [ ] consolidate Event to be a struct and/or protocol
* [ ] adopt an adapter-based approach for event store database

## Contributing

Everyone is welcome to contribute to Disco and help tackling existing issues!

Use the [issue tracker](https://github.com/andreapavoni/disco/issues) for bug reports or feature requests.

Please, do your best to follow the [Elixir's Code of Conduct](https://github.com/elixir-lang/elixir/blob/master/CODE_OF_CONDUCT.md).

## License

This source code is released under MIT License. Check [LICENSE](https://github.com/andreapavoni/disco/blob/master/LICENSE) file for more information.
