defmodule NillableSchema do
  @moduledoc """
  A schema with a field with nil values
  """

  use Ecto.Schema

  schema "nillable_schema" do
    # a field named "date" of type :date
    field :date, :date
    field :count, :integer
  end

  def seed do
    [
      {~D[2020-02-12], 1},
      {~D[2020-02-13], 2},
      {~D[2020-02-14], 3},
      {~D[2020-02-15], 4},
      {~D[2020-02-16], 5},
      # ---
      {~D[2020-02-17], 6},
      {nil, nil},
      {nil, nil},
      {nil, nil},
      {nil, nil},
      # ---
      {nil, nil},
      {nil, nil},
      {nil, nil},
      {nil, nil},
      {nil, nil}
    ]
    |> Enum.with_index()
    |> Enum.map(fn {{date, count}, index} ->
      %{id: index, date: date, count: count}
    end)
  end
end
