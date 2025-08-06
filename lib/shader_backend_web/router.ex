defmodule ShaderBackendWeb.Router do
  use ShaderBackendWeb, :router



  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ShaderBackendWeb do
    pipe_through :api
    post "/generate_shader", ShaderController, :create
  end

end
