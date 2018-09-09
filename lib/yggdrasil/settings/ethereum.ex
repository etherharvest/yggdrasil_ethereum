defmodule Yggdrasil.Settings.Ethereum do
  @moduledoc """
  This module defines the available settings for Ethereum in Yggdrasil.
  """
  use Skogsra

  @doc """
  Ethereum timeout. Defaults to `10_000`.

  It looks for the value following this order:

    1. The OS environment variable `$YGGDRASIL_ETHEREUM_TIMEOUT`.
    2. The configuration file.
    3. The default value `10_000`.

  If the timeout is defined using a namespace, the the name of the OS variable
  should be `$<NAMESPACE>_YGGDRASIL_ETHEREUM_TIMEOUT` where `<NAMESPACE>` is
  the snake case version of the actual namespace e.g. `MyApp.Namespace` would
  be `MYAPP_NAMESPACE`.

  ```
  config :yggdrasil, <NAMESPACE>,
    ethereum: [timeout: 10_000]
  ```
  """
  app_env :yggdrasil_ethereum_timeout, :yggdrasil, :timeout,
    default: 10_000,
    domain: :ethereum
end
