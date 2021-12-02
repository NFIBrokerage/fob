defmodule Fob.Repo.Migrations.CreateNillableSchema do
  use Ecto.Migration

  def change do
    create table(:nillable_schema) do
      # a field named "date" of type :date
      add :date, :date
      add :count, :integer
    end
  end
end
