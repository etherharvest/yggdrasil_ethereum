defmodule Yggdrasil.Subscriber.Adapter.EthereumTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias Yggdrasil.Channel
  alias Yggdrasil.Registry
  alias Yggdrasil.Backend
  alias Yggdrasil.Subscriber.Publisher
  alias Yggdrasil.Subscriber.Manager
  alias Yggdrasil.Subscriber.Adapter
  alias Yggdrasil.Settings

  alias EthEvent.Api.Balance

  @registry Settings.yggdrasil_process_registry()

  defmodule Transfer do
    use EthEvent.Schema

    event "Transfer" do
      address :from, indexed: true
      address :to, indexed: true
      uint256 :value
    end
  end

  describe "distributes message" do
    setup do
      mock_global &Yggdrasil.Ethereum.Node.server/1

      :ok
    end

    test "for balance event" do
      address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      channel = %Channel{
        name: {Balance, [address: address]},
        adapter: :ethereum,
        namespace: BalanceTest
      }
      {:ok, channel} = Registry.get_full_channel(channel)
      Backend.subscribe(channel)
      publisher = {:via, @registry, {Publisher, channel}}
      manager = {:via, @registry, {Manager, channel}}
      assert {:ok, _} = Publisher.start_link(channel, name: publisher)
      assert {:ok, _} = Manager.start_link(channel, name: manager)
      :ok = Manager.add(channel, self())

      assert {:ok, adapter} = Adapter.start_link(channel)
      assert_receive {:Y_CONNECTED, ^channel}, 500

      assert_receive {:Y_EVENT, ^channel, %Balance{}}, 500

      assert :ok = Adapter.stop(adapter)
      assert_receive {:Y_DISCONNECTED, ^channel}, 500

    end

    test "for custom event" do
      address = "0x8ca88e083ec89a8110b722ec46aace1c1d1b260e"
      channel = %Channel{
        name: {Transfer, [address: address]},
        adapter: :ethereum,
        namespace: TransferTest
      }
      {:ok, channel} = Registry.get_full_channel(channel)
      Backend.subscribe(channel)
      publisher = {:via, @registry, {Publisher, channel}}
      manager = {:via, @registry, {Manager, channel}}
      assert {:ok, _} = Publisher.start_link(channel, name: publisher)
      assert {:ok, _} = Manager.start_link(channel, name: manager)
      :ok = Manager.add(channel, self())

      assert {:ok, adapter} = Adapter.start_link(channel)
      assert_receive {:Y_CONNECTED, ^channel}, 500

      assert_receive {:Y_EVENT, ^channel, %Transfer{}}, 500

      assert :ok = Adapter.stop(adapter)
      assert_receive {:Y_DISCONNECTED, ^channel}, 500
    end
  end
end
