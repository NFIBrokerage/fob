use Mix.Config

config :fob, ecto_repos: [Fob.Repo]

config :logger, level: :info

import_config "#{Mix.env()}.exs"
