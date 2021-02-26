defmodule TieBreakerSchema do
  @moduledoc """
  A schema in which records will share values with one another
  """

  use Ecto.Schema

  schema "tie_breaker_schema" do
    field :date, :date
    field :name
  end
end
