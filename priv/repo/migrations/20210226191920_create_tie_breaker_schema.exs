defmodule Fob.Repo.Migrations.CreateTieBreakerSchema do
  use Ecto.Migration

  def change do
    create table(:tie_breaker_schema) do
      add :date, :date
      add :naive_datetime, :naive_datetime
      add :naive_datetime_usec, :naive_datetime_usec
      add :utc_datetime, :utc_datetime
      add :utc_datetime_usec, :utc_datetime_usec
      add :name, :string
    end
  end
end
