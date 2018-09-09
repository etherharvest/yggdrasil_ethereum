defmodule Yggdrasil.Subscriber.Adapter.Ethereum do
  @moduledoc """
  Yggdrasil subscriber adapter for Ethereum. The name of the channel must be
  a tuple with the `EthEvent` module and its parameters or a list of these
  tuples for composable events e.g:

  Subscription to channel:

  ```
  iex(1)> channel_name = {Balance, [address: "0x1234..."]}
  iex(2)> channel = %Yggdrasil.Channel{name: channel_name, adapter: :ethereum}}
  iex(3)> Yggdrasil.subscribe(channel)
  :ok
  iex(4)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: {Balance, (...)}, (...)}}
  ```

  And when a subscriber receives a message:

  ```
  iex(5)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: {Balance, (...)}}, %Balance{...}}
  ```

  The subscriber can also unsubscribe from the channel:

  ```
  iex(6)> Yggdrasil.unsubscribe(channel)
  :ok
  iex(7)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: {Balance, (...)}}}
  ```
  """
  use Yggdrasil.Subscriber.Adapter
  use GenServer

  require Logger

  alias Yggdrasil.Channel
  alias Yggdrasil.Subscriber.Publisher
  alias Yggdrasil.Subscriber.Manager
  alias Yggdrasil.Settings, as: GlobalSettings
  alias Yggdrasil.Settings.Ethereum, as: Settings

  alias EthEvent.Api.Block
  alias EthEvent.Api.Balance

  defstruct [
    channel: nil,
    from_block: nil,
    connected: false
  ]
  alias __MODULE__, as: State

  @impl true
  def init(%{channel: %Channel{} = channel} = arguments) do
    state = struct(State, arguments)
    with {:ok, new_state} <- update_block(state) do
      Logger.debug(fn ->
        "Started #{__MODULE__} for #{inspect channel}"
      end)
      {:ok, new_state, 0}
    else
      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  @impl true
  def handle_info(:timeout, %State{channel: channel} = state) do
    timeout = get_timeout(channel)
    with {:ok, %State{} = new_state} <- query(state) do
      {:noreply, new_state, timeout}
    end
  end

  @impl true
  def terminate(:normal, %State{channel: channel}) do
    Manager.disconnected(channel)
    Logger.debug(fn ->
      "Stopped #{__MODULE__} for #{inspect channel}"
    end)
  end
  def terminate(reason, %State{channel: channel}) do
    Manager.disconnected(channel)
    Logger.error(fn ->
      "Stopped #{__MODULE__} for #{inspect channel} due to #{inspect reason}"
    end)
  end

  #########
  # Helpers

  @doc false
  def update_block(%State{} = state) do
    with {:ok, %Block{} = block} <- Block.query() do
      add_block(block, state)
    else
      _ ->
        {:error, "Cannot update current block"}
    end
  end

  @doc false
  def add_block(%{block_number: current_block}, %State{} = state) do
    {:ok, %State{state | from_block: current_block}}
  end

  @doc false
  def query(
    %State{
      channel: %Channel{name: {module, parameters}},
      from_block: block,
    } = state
  ) do
    with {:ok, events} <- module.query(parameters, from_block: block) do
      connected(events, state)
    else
      {:error, reason} ->
        disconnected(reason, state)
    end
  end

  @doc false
  def connected(events, %State{channel: channel, connected: false} = state) do
    Logger.debug(fn ->
      "#{__MODULE__} connected for Ethereum #{inspect channel}"
    end)
    Manager.connected(channel)
    connected(events, %State{state | connected: true})
  end
  def connected(%{} = event, %State{} = state) do
    connected([event], state)
  end
  def connected([], %State{} = state) do
    {:ok, state}
  end
  def connected(events, %State{} = state) when is_list(events) do
    publish_events(events, state)
  end

  @doc false
  def disconnected(
    reason,
    %State{channel: channel, connected: true} = state
  ) do
    Manager.disconnected(channel)
    disconnected(reason, %State{state | connected: false})
  end
  def disconnected(
    reason,
    %State{channel: channel} = state
  ) do
    Logger.warn(fn ->
      "Cannot get new events for #{inspect channel} due to #{inspect reason}"
    end)
    {:ok, state}
  end

  @doc false
  def publish_events(events, %State{from_block: last_block} = state) do
    latest_block =
      events
      |> Stream.filter(fn event -> pick_event(event, state) end)
      |> Stream.map(fn event -> publish_event(event, state) end)
      |> Stream.map(fn event -> get_block_info(event) end)
      |> Stream.uniq()
      |> Enum.max(fn -> last_block end)
    {:ok, %State{state | from_block: latest_block}}
  end

  @doc false
  def pick_event(%Balance{block_number: nil}, _) do
    true
  end
  def pick_event(%{block_number: current}, %State{from_block: last}) do
    current > last
  end

  @doc false
  def publish_event(event, %State{channel: channel}) do
    Publisher.notify(channel, event)
    event
  end

  @doc false
  def get_block_info(%Balance{block_number: nil}) do
    %Block{block_number: block} = Block.query!()
    block
  end
  def get_block_info(%{block_number: block}) do
    block
  end

  @doc false
  def get_value(namespace, key, default) do
    name = GlobalSettings.gen_env_name(namespace, key, "_YGGDRASIL_ETHEREUM_")
    Skogsra.get_app_env(:yggdrasil, key,
      domain: [namespace, :ethereum],
      default: default,
      name: name
    )
  end

  @doc false
  def get_timeout(%Channel{namespace: namespace}) do
    get_timeout(namespace)
  end
  def get_timeout(Yggdrasil) do
    Settings.yggdrasil_ethereum_timeout()
  end
  def get_timeout(namespace) do
    get_value(namespace, :timeout, get_timeout(Yggdrasil))
  end
end
