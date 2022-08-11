defmodule TrunkSchema do
  @moduledoc false
  # A trunk schema onto which other records will be joined

  use Ecto.Schema

  schema "trunk_schema" do
    field :child, :integer
    field :child_name, :string, virtual: true
    field :id_next, :integer, virtual: true
  end
end

defmodule ChildSchema do
  @moduledoc false
  # A schema which will be joined onto the trunk

  use Ecto.Schema

  schema "child_schema" do
    field :name
  end
end
