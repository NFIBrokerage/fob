defmodule Fob.PrimaryKeyTest do
  use Fob.RepoCase

  @moduledoc """
  Tests basic functionality where a query is only sorted on the primary key
  """

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

  end

  test "when sorting ascending, we can get each page", c do
    cursor =
      Cursor.new(
        order_by(c.schema, [asc: :id]),
        c.repo,
        _initial_page_breaks = nil,
        5
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(1..5)

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(6..10)

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(11..15)

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(16..20)

    # end of the data set
    assert {[], _cursor} = Cursor.next(cursor)
  end

  test "when sorting descending, the records are in reverse order", c do
    cursor =
      Cursor.new(order_by(c.schema, [desc: :id]), c.repo, nil, 10)

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(20..11)

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == Enum.to_list(10..1)

    assert {[], _cursor} = Cursor.next(cursor)
  end
end
