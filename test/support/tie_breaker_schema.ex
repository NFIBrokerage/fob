defmodule TieBreakerSchema do
  @moduledoc false
  # A schema in which records will share values with one another

  use Ecto.Schema

  schema "tie_breaker_schema" do
    field :date, :date
    field :name
  end

  def seed do
    [
      {~D[2020-12-15], "a", 0},
      {~D[2020-12-15], "a", 1},
      {~D[2020-12-15], "a", 2},
      {~D[2020-12-15], "a", 3},
      {~D[2020-12-15], "b", 4},
      {~D[2020-12-15], "b", 5},
      {~D[2020-12-15], "b", 6},
      {~D[2020-12-15], "b", 7},
      {~D[2020-12-15], nil, 8},
      {~D[2020-12-15], nil, 9},
      {~D[2020-12-17], nil, 10},
      {~D[2020-12-17], "b", 11},
      {~D[2020-12-17], "b", 12},
      {~D[2020-12-17], "c", 13},
      {~D[2020-12-17], "c", 14},
      {nil, "c", 15},
      {nil, "c", 16},
      {nil, "c", 17},
      {nil, "c", 18},
      {nil, "c", 19}
    ]
    |> Enum.map(fn {date, name, index} ->
      %{id: index, name: name, date: date}
    end)
  end
end
