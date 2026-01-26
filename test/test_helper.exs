[
  Fob.Repo
]
|> Supervisor.start_link(strategy: :one_for_one)

ExUnit.start()
