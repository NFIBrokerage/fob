defmodule Fob.Repo do
  use Ecto.Repo, otp_app: :fob, adapter: Ecto.Adapters.Postgres

  @moduledoc false
end
