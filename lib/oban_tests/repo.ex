defmodule ObanTests.Repo do
  use Ecto.Repo,
    otp_app: :oban_tests,
    adapter: Ecto.Adapters.Postgres
end
