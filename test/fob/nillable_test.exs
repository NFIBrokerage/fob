defmodule Fob.NillableTest do
  use Fob.RepoCase

  @moduledoc """
  A test case for ensuring that nils don't break pagination

  This is a common gripe for keyset pagination and is mostly a problem from
  a SQL comparison perspective: `f.foo > nil` doesn't really work as you might
  expect. To remedy this, we used to test equality with `is_nil/1` and do comparisons
  against the postgres-specific `fragment("'-infinity'")` and
  `fragment("'infinity'")` (depending on the direction of the sort of the
  column). However, this doesn't work for numerics in even modern versions of
  postgres. Instead we optimize to checking `is_nil(column) == false`, which
  works out to effectively be the same check.
  """

  alias Fob.Cursor
  alias Ecto.Multi
  import Enum, only: [to_list: 1]

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

  test "we can get all pages when sorting ascending (default) by date", c do
    cursor =
      Cursor.new(
        order_by(c.schema, asc: :date, asc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(0..4)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-12], ~D[2020-02-16]) |> to_list()

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == [5, 6, 7, 8, 9]

    assert records |> Enum.map(& &1.date) == [~D[2020-02-17] | repeat(nil, 4)]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(10..14)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting descending by integer type", c do
    cursor =
      Cursor.new(
        order_by(c.schema, desc: :count, asc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(6..10)
    assert records |> Enum.map(& &1.count) == repeat(nil, 5)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == [11, 12, 13, 14, 5]
    assert records |> Enum.map(& &1.count) == repeat(nil, 4) ++ [6]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(4..0)
    assert records |> Enum.map(& &1.count) == to_list(5..1)

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting ascending by integer type", c do
    cursor =
      Cursor.new(
        order_by(c.schema, asc: :count, asc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.count) == to_list(1..5)
    assert records |> Enum.map(& &1.id) == to_list(0..4)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.count) == [6 | repeat(nil, 4)]
    assert records |> Enum.map(& &1.id) == to_list(5..9)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.count) == repeat(nil, 5)
    assert records |> Enum.map(& &1.id) == to_list(10..14)

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting ascending (nulls last)", c do
    cursor =
      Cursor.new(
        order_by(c.schema, asc_nulls_last: :date, asc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(0..4)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-12], ~D[2020-02-16]) |> to_list()

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(5..9)

    assert records |> Enum.map(& &1.date) == [~D[2020-02-17] | repeat(nil, 4)]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(10..14)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting ascending (nulls first)", c do
    cursor =
      Cursor.new(
        order_by(c.schema, asc_nulls_first: :date, asc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(6..10)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == [11, 12, 13, 14, 0]

    assert records |> Enum.map(& &1.date) == repeat(nil, 4) ++ [~D[2020-02-12]]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(1..5)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-13], ~D[2020-02-17]) |> to_list()

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting descending (default)", c do
    cursor =
      Cursor.new(
        order_by(c.schema, desc: :date, desc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(14..10)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(9..5)

    assert records |> Enum.map(& &1.date) == repeat(nil, 4) ++ [~D[2020-02-17]]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(4..0)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-16], ~D[2020-02-12]) |> to_list()

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting descending (nulls first)", c do
    cursor =
      Cursor.new(
        order_by(c.schema, desc_nulls_first: :date, desc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(14..10)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(9..5)
    assert records |> Enum.map(& &1.date) == repeat(nil, 4) ++ [~D[2020-02-17]]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(4..0)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-16], ~D[2020-02-12]) |> to_list()

    {[], _cursor} = Cursor.next(cursor)
  end

  test "we can get all pages when sorting descending (nulls last)", c do
    cursor =
      Cursor.new(
        order_by(c.schema, desc_nulls_last: :date, desc: :id),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(5..1)

    assert records |> Enum.map(& &1.date) ==
             Date.range(~D[2020-02-17], ~D[2020-02-13]) |> to_list()

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == [0, 14, 13, 12, 11]
    assert records |> Enum.map(& &1.date) == [~D[2020-02-12] | repeat(nil, 4)]

    {records, cursor} = Cursor.next(cursor)

    assert records |> Enum.map(& &1.id) == to_list(10..6)
    assert records |> Enum.map(& &1.date) == repeat(nil, 5)

    {[], _cursor} = Cursor.next(cursor)
  end

  defp repeat(value, times), do: for(_n <- 1..times, do: value)
end
