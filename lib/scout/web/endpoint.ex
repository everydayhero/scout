defmodule Scout.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :scout

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  # plug Plug.Static,
  #   at: "/", from: :scout, gzip: false,
  #   only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_scout_key",
    signing_salt: "k8JLqRKT"
  )

  plug(Scout.Web.Router)

  @doc """
  Dynamically loads configuration from the system environment
  on startup.

  It receives the endpoint configuration from the config files
  and must return the updated configuration.
  """
  def load_from_system_env(config) do
    host = System.get_env("HOST") || raise "expected the HOST environment variable to be set"
    port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
    url = Keyword.merge(config[:url], host: host, port: port)

    config =
      config
      |> Keyword.put(:http, port: port)
      |> Keyword.put(:url, url)

    {:ok, config}
  end
end
