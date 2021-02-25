use Mix.Config

config :fob, Fob.Repo,
  database: "fob_test",
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox
