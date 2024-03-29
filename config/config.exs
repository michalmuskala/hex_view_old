# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :hex_view, HexView.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "U9zu6sFEwlUoknYRYUv5MOqFHaOiHmj/9jVeFxm/rMooK8sR/W8eCYRnWuY5+W3y",
  render_errors: [view: HexView.ErrorView, accepts: ~w(html json)],
  pubsub: [name: HexView.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :hex_view, HexView.Registry,
  base_url: "https://repo.hex.pm",
  storage:  "/tmp/hex_view",
  refresh:  60 * 60 * 1000,
  download_limit: 10,
  small_package_limit: 1024 * 1024

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ssl, protocol_version: :"tlsv1.2"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
