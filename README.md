# Disco

Simple, opinionated yet flexible library to build CQRS/ES driven systems.

## Status (2018-12-08)

Disco has been extracted from work done to build apps following the CQRS/ES pattern.
Several ideas come from other excellent examples such as [commanded](https://github.com/commanded/commanded).
However, the goal was to build something simpler and more flexible, because it's not always
possible to follow 100% CQRS/ES pattern neither anywhere in your apps. Disco tries to
solve this gap.

### Production ready?

Not yet. Well, this approach and code has been used to build several apps in production without problems,
however before being really usable, it needs some polishing.

## Installation

The package is available in [Hex](https://hex.pm/packages/disco), follow these steps to install:

1.  Add `disco` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  # Get from hex
  [{:disco, "~> 0.1.0"}]
  # Or use the latest from master
  [{:disco, github: "andreapavoni/disco"}]
end
```

2.  Run setup to generate event store migrations:

```sh
mix do deps.get, compile, disco.install
```

## Usage

Quick and dirty usage, to show how it's supposed to work.

```
$ iex -S mix
# start Core process with the available aggregates
iex(1)> Disco.start_link [MyApp.Wallet]
{:ok, #PID<0.327.0>}

# get available commands
iex(2)> Disco.commands()
[:create_wallet]

# execute a command (sync)
iex(3)> Disco.dispatch(:create_wallet, %{user_id: UUID.uuid4(), balance: 100.0})
{:ok, %MyApp.Wallet.Aggregate{
  balance: 100.0,
  id: "4fd98a9e-8d6f-4e35-a8fc-aca5544596cb",
  user_id: "13bbece9-9bf3-4158-92b4-7e8a62d62361"
}}

# execute a command (async -> returns {:ok, aggregate_id})
iex(4)> Disco.dispatch(:create_wallet, %{user_id: UUID.uuid4(), balance: 100.0}, async: true)
{:ok, "ce998b0d-8d6f-4e35-a8fc-aca5544596cb"}

# execute invalid command
iex(5)> Disco.dispatch(:create_wallet, %{balance: 100.0})
{:error, %{user_id: ["must be a valid UUID string"]}}

# get available queries
iex(6)> Disco.queries()
[:list_wallets]

# list user wallets
iex(7)> Disco.query(:list_wallets, %{user_id: "13bbece9-9bf3-4158-92b4-7e8a62d62361"})
[%{
  balance: 100.0,
  id: "4fd98a9e-8d6f-4e35-a8fc-aca5544596cb",
  user_id: "13bbece9-9bf3-4158-92b4-7e8a62d62361"
}]

# execute invalid query
iex(8)> Disco.query(:list_wallets, %{})
{:error, %{user_id: ["must be a valid UUID string"]}}
```

## Documentation

The docs aren't ready/published yet. They will be available at [https://hexdocs.pm/disco](https://hexdocs.pm/disco).
Meanwhile you can check the source code and tests.

## TODO

* [ ] improve overall documentation
* [ ] consolidate API (mostly based on feedback, if any)
* [ ] adopt an adapter-based approach for event store database
* [ ] add example app

## Contributing

Everyone is welcome to contribute to PlugEtsCache and help tackling existing issues!

Use the [issue tracker](https://github.com/andreapavoni/disco/issues) for bug reports or feature requests.

Please, do your best to follow the [Elixir's Code of Conduct](https://github.com/elixir-lang/elixir/blob/master/CODE_OF_CONDUCT.md).

## License

This source code is released under MIT License. Check [LICENSE](https://github.com/andreapavoni/disco/blob/master/LICENSE) file for more information.
