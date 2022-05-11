defmodule ChooseFieldSchema do
  @moduledoc false
  # This schema is meant to test the casting of page break values
  # when ordering by a fragment

  use Ecto.Schema

  defmacro date(schema) do
    quote do
      fragment(
        "case ? when 'a' then ? when 'b' then ? else null end",
        unquote(schema).mode,
        unquote(schema).date_a,
        unquote(schema).date_b
      )
    end
  end

  schema "choose_field_schema" do
    field :date, :date, virtual: true
    field :date_a, :date
    field :date_b, :date
    field :mode, :string
  end

  def seed do
    [
      {0, "a", ~D[2020-12-15]},
      {1, "a", ~D[2020-12-16]},
      {2, "a", ~D[2020-12-17]},
      {3, "a", ~D[2020-12-18]},
      {4, "b", ~D[2020-12-15]},
      {5, "b", ~D[2020-12-16]},
      {6, "b", ~D[2020-12-17]},
      {7, "b", ~D[2020-12-18]},
      {8, "b", ~D[2020-12-15]},
      {9, "b", ~D[2020-12-16]},
      {10, "b", ~D[2020-12-17]},
      {11, "b", ~D[2020-12-19]},
      {12, "b", ~D[2020-12-20]},
      {13, "c", ~D[2020-12-21]},
      {14, "c", ~D[2020-12-22]},
      {15, "c", nil},
      {16, "c", nil},
      {17, "c", nil},
      {18, "c", nil},
      {19, "c", nil}
    ]
    |> Enum.map(fn {index, mode, date} ->
      # it's not very important to this test case that
      %{id: index, mode: mode, date_a: date, date_b: date}
    end)
  end
end
