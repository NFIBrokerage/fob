defmodule Fob.ComplexOrderByTest do
  use Fob.RepoCase

  @moduledoc false

  # Tests functionality where a query is sorted by a complex fragment

  alias Fob.Cursor
  alias Ecto.Multi

  setup do
    [schema: SimplePrimaryKeySchema, repo: Fob.Repo]
  end

  setup c do
    records = for n <- 1..20, do: %{id: n}

    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, records)
    |> c.repo.transaction()

    :ok
  end

  test "when sorting ascending with fragment, we can get each page", c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment("(? % 2)", s.id)
          },
          order_by: [asc: fragment("(? % 2)", s.id), asc: s.id]
        ),
        c.repo,
        _initial_page_breaks = nil,
        5
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [2, 4, 6, 8, 10]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [12, 14, 16, 18, 20]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [1, 3, 5, 7, 9]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [11, 13, 15, 17, 19]

    # end of the data set
    assert {[], _cursor} = Cursor.next(cursor)
  end

  test "when sorting descending with fragment, the records are in reverse order",
       c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment("(? % 2)", s.id)
          },
          order_by: [desc: fragment("(? % 2)", s.id), desc: s.id]
        ),
        c.repo,
        nil,
        10
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [19, 17, 15, 13, 11, 9, 7, 5, 3, 1]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [20, 18, 16, 14, 12, 10, 8, 6, 4, 2]

    assert {[], _cursor} = Cursor.next(cursor)
  end
end
