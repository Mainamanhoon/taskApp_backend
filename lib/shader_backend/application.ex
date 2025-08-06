defmodule ShaderBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting ShaderBackend application...")

    # Check environment variables
    Logger.info("PORT: #{System.get_env("PORT")}")
    Logger.info("MIX_ENV: #{System.get_env("MIX_ENV")}")
    Logger.info("PHX_SERVER: #{System.get_env("PHX_SERVER")}")

    # Manually configure endpoint for production if runtime.exs is not working
    if System.get_env("MIX_ENV") == "prod" do
      Logger.info("=== Manually configuring endpoint for production ===")
      port = String.to_integer(System.get_env("PORT") || "4000")
      secret_key_base = System.get_env("SECRET_KEY_BASE")

      Logger.info("Setting endpoint config - port: #{port}")

      Application.put_env(:shader_backend, ShaderBackendWeb.Endpoint,
        http: [ip: {0, 0, 0, 0}, port: port],
        server: true,
        secret_key_base: secret_key_base
      )
    end

    children = [
       {Phoenix.PubSub, name: ShaderBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ShaderBackend.Finch},
      # Start a worker by calling: ShaderBackend.Worker.start_link(arg)
      # {ShaderBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      ShaderBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShaderBackend.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("ShaderBackend application started successfully")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start ShaderBackend application: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShaderBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
