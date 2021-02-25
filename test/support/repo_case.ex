defmodule Fob.RepoCase do
  use ExUnit.CaseTemplate

  @moduledoc false

  using do
    quote do
      alias Fob.Repo

      import Ecto
      import Ecto.Query
      import Fob.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Fob.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Fob.Repo, {:shared, self()})
    end

    :ok
  end
end
