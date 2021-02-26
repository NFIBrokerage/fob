defmodule Fob.Repo.Migrations.CreateLeftJoinSchemas do
  use Ecto.Migration

  def change do
    create table(:trunk_schema) do
      add :child, :integer
    end

    create table(:child_schema) do
      add :name, :string
    end
  end
end
