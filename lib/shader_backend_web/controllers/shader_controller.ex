defmodule ShaderBackendWeb.ShaderController do
  use ShaderBackendWeb, :controller
  alias ShaderBackend.ShaderGenerator

  def create(conn, %{"description" => desc}) do
    case ShaderGenerator.generate(desc) do
      {:ok, code}   -> json(conn, %{shader_code: code})
      {:error, msg} -> conn |> put_status(:bad_request) |> json(%{error: msg})
    end
  end

  def create(conn, _),
    do: conn |> put_status(:bad_request) |> json(%{error: "Description parameter is required"})
end
