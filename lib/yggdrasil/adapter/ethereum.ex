defmodule Yggdrasil.Adapter.Ethereum do
  @moduledoc """
  Yggdrasil adapter for Ethereum. It does not support publishing of events,
  because it does not make sense for Ethereum and its events.

  The name of the channel must be an `EthEvent` struct e.g:

  Subscription to channel:

  ```
  iex(1)> channel = %Yggdrasil.Channel{
  iex(1)>   name: %Balance{address: "0x1234...", adapter: :ethereum}
  iex(1)> }
  iex(2)> Yggdrasil.subscribe(channel)
  :ok
  iex(3)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: %Balance{...}, (...)}}
  ```

  And when a subscriber receives a message:

  ```
  iex(4)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: %Balance{...}}, %Balace{...}}
  ```

  The subscriber can also unsubscribe from the channel:

  ```
  iex(5)> Yggdrasil.unsubscribe(channel)
  :ok
  iex(6)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: %Balance{...}}}
  ```
  """
  use Yggdrasil.Adapter, name: :ethereum
end
