defmodule Fob.NillableComplexOrderByTest do
  use Fob.RepoCase
  alias Fob.Cursor
  alias Ecto.Multi

  @day_of_week_sort "(EXTRACT(DOW FROM ?))"

  setup do
    [schema: NillableSchema, repo: Fob.Repo]
  end

  setup c do
    records = c.schema.seed()

    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, records)
    |> c.repo.transaction()

    :ok
  end

  test "when sorting ascending nulls first with fragment, we can get each page",
       c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment(@day_of_week_sort, s.date)
          },
          order_by: [
            asc_nulls_first: fragment(@day_of_week_sort, s.date),
            asc: s.id
          ]
        ),
        c.repo,
        _initial_page_breaks = nil,
        5
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [6, 7, 8, 9, 10]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [11, 12, 13, 14, 4]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [5, 0, 1, 2, 3]

    # end of the data set
    assert {[], _cursor} = Cursor.next(cursor)
  end

  test "when sorting ascending nulls last with fragment, we can get each page",
       c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment(@day_of_week_sort, s.date)
          },
          order_by: [
            asc_nulls_last: fragment(@day_of_week_sort, s.date),
            asc: s.id
          ]
        ),
        c.repo,
        _initial_page_breaks = nil,
        5
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [4, 5, 0, 1, 2]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [3, 6, 7, 8, 9]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [10, 11, 12, 13, 14]

    # end of the data set
    assert {[], _cursor} = Cursor.next(cursor)
  end

  test "when sorting descending nulls first with fragment, the records are in reverse order",
       c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment(@day_of_week_sort, s.date)
          },
          order_by: [
            desc_nulls_first: fragment(@day_of_week_sort, s.date),
            desc: s.id
          ]
        ),
        c.repo,
        nil,
        10
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [14, 13, 12, 11, 10, 9, 8, 7, 6, 3]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [2, 1, 0, 5, 4]

    assert {[], _cursor} = Cursor.next(cursor)
  end

  test "when sorting descending nulls last with fragment, the records are in reverse order",
       c do
    cursor =
      Cursor.new(
        from(
          s in c.schema,
          select: %{
            id: s.id,
            virtual_column: fragment(@day_of_week_sort, s.date)
          },
          order_by: [
            desc_nulls_last: fragment(@day_of_week_sort, s.date),
            desc: s.id
          ]
        ),
        c.repo,
        nil,
        5
      )

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [3, 2, 1, 0, 5]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [4, 14, 13, 12, 11]

    assert {records, cursor} = Cursor.next(cursor)
    assert Enum.map(records, & &1.id) == [10, 9, 8, 7, 6]

    assert {[], _cursor} = Cursor.next(cursor)
  end
end
