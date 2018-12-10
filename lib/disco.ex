defmodule Disco do
  @moduledoc """
  Disco: simple, opinionated and flexible library to build CQRS/ES driven systems 🕺.

  This library is the result of the know how achieved by working on projects using CQRS/ES.
  `Disco` offers a set of behaviours along with some default implementations of the
  callbacks to make the developer life easier.

  However, following a CQRS/ES pattern can be hard when it comes to follow a rigid structure:
  each domain brings a set of requirements that need flexibility. That's how `Disco` tries
  to solve this problem.

  ## Components

  `Disco` is mainly composed by the following pieces:

  `Disco.Aggregate` is the main interface to interact with an aggregate. It exposes the
  necessary functionalities to dispatch a `Disco.Command` that emits a set of events and
  process them to update the aggregate state. Later, the aggregate can be used to run a
  `Disco.Query` to retrieve data from some source of data, ideally the one where you wrote
  using a `Disco.EventConsumer` event processor.

  `Disco.Orchestrator` acts like the `Disco.Aggregate` in terms of commands and queries
  functionalities, except that it groups multiple aggregates under the same module. It
  comes particularly useful when dealing with several aggregates. For example, working on
  an umbrella project might need a central point where to handle all the commands and queries.

  `Disco.EventStore` is responsible to persist and retrieve emitted events. To interact with
  it, a `Disco.EventStore.Client` is used, so that everything is isolated from exposing
  unnecessary implementation details.

  `Disco.EventConsumer` is used to retrieve and process events, even from different apps.

  Each component follows the relative behaviour and implements a default for as many callbacks
  as possible, to hopefully cover the most common use cases. Check the documentation of
  each component for details.
  """
end
