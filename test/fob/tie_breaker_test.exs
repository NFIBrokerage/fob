defmodule Fob.TieBreakerTest do
  use Fob.RepoCase

  @moduledoc false
  # Tests that records which have ties in sortable keys have those ties correctly
  # broken by keyset pagination

  alias Fob.Cursor
  alias Ecto.Multi

  setup do
    [schema: TieBreakerSchema, repo: Fob.Repo]
  end

  setup c do
    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, c.schema.seed())
    |> c.repo.transaction()

    :ok
  end

  @criteria_to_order %{
    [asc_nulls_last: :date, desc_nulls_last: :name, asc: :id] => [
      4,
      5,
      6,
      7,
      0,
      1,
      2,
      3,
      8,
      9,
      13,
      14,
      11,
      12,
      10,
      15,
      16,
      17,
      18,
      19
    ],
    [asc_nulls_last: :date, asc_nulls_last: :name, asc: :id] => [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      11,
      12,
      13,
      14,
      10,
      15,
      16,
      17,
      18,
      19
    ],
    [desc_nulls_first: :date, asc: :name, desc: :id] => [
      19,
      18,
      17,
      16,
      15,
      12,
      11,
      14,
      13,
      10,
      3,
      2,
      1,
      0,
      7,
      6,
      5,
      4,
      9,
      8
    ],
    [desc_nulls_first: :name, desc_nulls_first: :date, desc: :id] => [
      10,
      9,
      8,
      19,
      18,
      17,
      16,
      15,
      14,
      13,
      12,
      11,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
      0
    ]
  }

  for {criteria, expected_order} <- @criteria_to_order do
    @criteria criteria
    @expected_order expected_order

    describe inspect(@criteria) do
      setup do
        [criteria: @criteria, expected_order: @expected_order]
      end

      test "sorting gives proper page breaks", c do
        criteria = c.criteria

        # at a page size of 5, it should take us 4 pages to get all 19 records
        cursor =
          Cursor.new(
            order_by(c.schema, ^criteria),
            c.repo,
            _initial_page_breaks = nil,
            5
          )

        assert {records, _cursor} = Cursor.split(cursor, 4)

        assert records |> Enum.map(& &1.id) == Enum.to_list(c.expected_order)
      end
    end
  end
end
