use Mix.Config

config :logger,
  level: :error

config :tesla,
  adapter: Tesla.Mock
