use Mix.Config

config :fob, ecto_repos: [Fob.Repo]

import_config "#{Mix.env()}.exs"
