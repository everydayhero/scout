# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :dev
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: System.get_env("COOKIE") |> String.to_atom()
end

release :scout do
  set version: current_version(:scout)
  set applications: [
    :runtime_tools
  ]
end
