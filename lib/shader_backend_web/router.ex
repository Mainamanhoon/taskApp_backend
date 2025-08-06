defmodule ShaderBackendWeb.Router do
  use ShaderBackendWeb, :router



  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check endpoint
  get "/health", ShaderBackendWeb.HealthController, :check

  scope "/api", ShaderBackendWeb do
    pipe_through :api
    post "/generate_shader", ShaderController, :create
  end

end
