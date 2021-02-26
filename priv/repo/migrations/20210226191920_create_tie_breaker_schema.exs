defmodule Fob.Repo.Migrations.CreateTieBreakerSchema do
  use Ecto.Migration

  def change do
    create table(:tie_breaker_schema) do
      add :date, :date
      add :name, :string
    end
  end
end
