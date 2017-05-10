# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :scout,
  ecto_repos: [Scout.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :scout, Scout.Web.Endpoint,
  url: [host: "localhost", path: "/"],
  on_init: {Scout.Web.Endpoint, :load_from_system_env, []},
  secret_key_base: "R2bKnt1Q6y27lyEECifkZBtCTfZkBkvEWOJRD3oHGUZY+OKRFi6+lQP+UvGqPL05",
  render_errors: [view: Scout.Web.ErrorView, accepts: ~w(json)],
  pubsub: [name: Scout.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
