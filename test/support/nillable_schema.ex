defmodule NillableSchema do
  @moduledoc """
  A schema with a field with nil values
  """

  use Ecto.Schema

  schema "nillable_schema" do
    # a field named "date" of type :date
    field :date, :date
  end
end
