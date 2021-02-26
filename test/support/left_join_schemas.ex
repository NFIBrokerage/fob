defmodule TrunkSchema do
  @moduledoc """
  A trunk schema onto which other records will be joined
  """

  use Ecto.Schema

  schema "trunk_schema" do
    field :child, :integer
  end
end

defmodule ChildSchema do
  @moduledoc """
  A schema which will be joined onto the trunk
  """

  use Ecto.Schema

  schema "child_schema" do
    field :name
  end
end
