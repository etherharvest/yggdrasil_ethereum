# Ethereum adapter for Yggdrasil

[![Build Status](https://travis-ci.org/gmtprime/yggdrasil_ethereum.svg?branch=master)](https://travis-ci.org/gmtprime/yggdrasil_ethereum) [![Hex pm](http://img.shields.io/hexpm/v/yggdrasil_ethereum.svg?style=flat)](https://hex.pm/packages/yggdrasil_ethereum) [![hex.pm downloads](https://img.shields.io/hexpm/dt/yggdrasil_ethereum.svg?style=flat)](https://hex.pm/packages/yggdrasil_ethereum)

This project is an Ethereum adapter for `Yggdrasil` publisher/subscriber.

![demo](https://raw.githubusercontent.com/gmtprime/yggdrasil_ethereum/master/images/demo.gif)

## Small example

The following example uses Ethereum adapter to distribute messages:

First we need to configure [EthEvent](https://github.com/etherharvest/eth_event)
which is the library use to request the events from contracts:

```elixir
config :eth_event,
  node_url: "https://mainnet.infura.io/v3", # Can be a custom URL
  node_key: "" # Empty for custom URL
```

And then we declare the event using the library:

```elixir
iex(1)> defmodule Transfer do
iex(1)>   use EthEvent.Schema
iex(1)>
iex(1)>   event "Transfer" do
iex(1)>     address :from, indexed: true
iex(1)>     address :to, indexed: true
iex(1)>     uint256 :value
iex(1)>   end
iex(1)> end
```

We can subscribe to any contract that has that type of event:

```elixir
iex(2)> contract = "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07" # OmiseGo
iex(3)> channel = %Yggdrasil.Channel{
iex(3)>   name: {Transfer, [address: contract]},
iex(3)>   adapter: :ethereum
iex(3)> }
iex(4)> Yggdrasil.subscribe(channel)
iex(5)> flush()
{:Y_CONNECTED, %Yggdrasil.Channel{(...)}}
```

If we wait enough, we should receive a message as follows:

```elixir
iex(6)> flush()
{:Y_EVENT, %Yggdrasil.Channel{(...)}, %Transfer{(...)}}
```

When we want to stop receiving messages, then we can unsubscribe
from the channel as follows:

```elixir
iex(7)> Yggdrasil.unsubscribe(channel)
iex(8)> flush()
{:Y_DISCONNECTED, %Yggdrasil.Channel{(...)}}
```

## Ethereum adapter

The Ethereum adapter has the following rules:
  * The `adapter` name is identified by the atom `:ethereum`.
  * The channel `name` must be a tuple with the module name of the event and
  the `Keyword` list of options e.g: `:address`, `:from`, `:to`, etc (depends
  on the event).
  * The `transformer` should be always `:default`.
  * Any `backend` can be used (by default is `:default`).

The following is an example of a valid channel for the subscribers:

```elixir
%Yggdrasil.Channel{
  name: {Balance, [address: "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE"]},
  adapter: :ethereum
}
```

It will subscribe to the balance of that address.

## Ethereum configuration

This adapter uses long-polling to get the information from the Ethereum node
and the frequency of the requests can be configured with the `:timeout`
parameter.

The following shows a configuration with and without namespace:

```elixir
# Without namespace
config :yggdrasil,
  ethereum: [timeout: 5_000]

# With namespace
config :yggdrasil, EthereumOne,
  ethereum: [timeout: 15_000]
```

Additionally, we can configure `EthEvent` options:

  * `node_url` - The Ethereum node URL.
  * `node_key` - It'll be appended to the URL at the end.

```elixir
config :eth_event,
  node_url: "https://mainnet.infura.io/v3", # Can be a custom URL
  node_key: "some_key" # Empty for custom URL
```

All the options can be provided as OS environment variables. The available
variables are:

  * `YGGDRASIL_ETHEREUM_TIMEOUT` or `<NAMESPACE>_YGGDRASIL_ETHEREUM_TIMEOUT`.
  * `ETH_EVENT_NODE_URL`.
  * `ETH_EVENT_NODE_KEY`.

where `<NAMESPACE>` is the snakecase of the namespace chosen e.g. for the
namespace `EthereumTwo`, you would use `ETHEREUM_TWO` as namespace in the OS
environment variable.

## Installation

Using this Ethereum adapter with `Yggdrasil` is a matter of adding the available
hex package to your `mix.exs` file e.g:

```elixir
def deps do
  [{:yggdrasil_ethereum, "~> 0.1"}]
end
```

## Relevant projects used

  * [`EthEvent`](https://github.com/etherharvest/eth_event): Library for
  Solidity events.

## Author

Alexander de Sousa.

## License

`Yggdrasil` is released under the MIT License. See the LICENSE file for further
details.
