defmodule ShaderBackendWeb.HealthController do
  use ShaderBackendWeb, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", message: "Application is running"})
  end
end
