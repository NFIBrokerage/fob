defmodule Fob.Repo.Migrations.CreateChooseFieldSchema do
  use Ecto.Migration

  def change do
    create table(:choose_field_schema) do
      add :date_a, :date
      add :date_b, :date
      add :mode, :string
    end
  end
end
