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

  `Disco.Command` exposes the necessary functionalities to write a state and
  emit events if necessary.

  `Disco.Query` exposes the necessary functionalities to read data from a state.

  `Disco.EventStore` is responsible to persist and retrieve emitted events. To interact with
  it, a `Disco.EventStore.Client` is used, so that everything is isolated from exposing
  unnecessary implementation details.

  `Disco.EventConsumer` is used to retrieve and process events, even from different apps.

  Each component defines a proper behaviour and implements as many default callbacks as
  possible, to hopefully cover the most common use cases. Check the documentation
  of each component for details.
  """
end
