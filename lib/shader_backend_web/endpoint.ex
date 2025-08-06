defmodule ShaderBackendWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :shader_backend

  # ---- CORS (React dev server) ----
  plug CORSPlug,
    origin: ["http://localhost:5173"],
    methods: ["GET", "POST"]

  # ---- Static assets (none, but keep default plug) ----
  plug Plug.Static,
    at: "/",
    from: :shader_backend,
    gzip: false,
    only_matching: ~w()

  # Code reloader (dev only)
  if code_reloading? do
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  # no sessions needed for pure API

  plug ShaderBackendWeb.Router
end
