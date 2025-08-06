import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shader_backend, ShaderBackendWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cLjJ48UeaFb3+vj4HOFtj4r8SmV/UIXemKwwLsK3vpuruHuKEs8jM8c6F2KnEfpH",
  server: false

# In test we don't send emails
config :shader_backend, ShaderBackend.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
