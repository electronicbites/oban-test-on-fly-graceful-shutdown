import Config
config :ash, policies: [show_policy_breakdowns?: true]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :oban_tests, ObanTestsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "wJceE3LtEceHvx6ZAiCk8l71K2AmrtYIqtYZY5G8clHZZOrHdK7y7QTpRp7brfh4",
  server: false

# Disable Oban job processing during tests
config :oban_tests, Oban, testing: :manual

# In test we don't send emails
config :oban_tests, ObanTests.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
