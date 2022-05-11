defmodule Fob.LeftJoinTest do
  use Fob.RepoCase

  @moduledoc false

  # A testing case for schemas which are joined via a left-join

  alias Fob.Cursor
  alias Ecto.Multi

  setup do
    [repo: Fob.Repo, trunk_schema: TrunkSchema, child_schema: ChildSchema]
  end

  setup c do
    trunk_records = for n <- 1..20, do: %{id: n - 1, child: 20 - n}

    child_records =
      for n <- 1..20 do
        %{id: n - 1, name: String.pad_trailing("", n, "a")}
      end

    Multi.new()
    |> Multi.insert_all(:trunk_seeds, c.trunk_schema, trunk_records)
    |> Multi.insert_all(:child_seeds, c.child_schema, child_records)
    |> c.repo.transaction()

    :ok
  end

  test """
       we can sort _ascending_ by a left-joined field,
       even if renamed in the select clause
       """,
       c do
    child_schema = c.child_schema

    cursor =
      Cursor.new(
        from(t in c.trunk_schema,
          left_join: c in ^child_schema,
          on: t.child == c.id,
          select: %{t | child_name: c.name},
          order_by: [asc: c.name, desc: t.id]
        ),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    records
    |> Enum.with_index(1)
    |> Enum.each(fn {record, index} ->
      assert String.length(record.child_name) == index
    end)

    {records, _cursor} = Cursor.next(cursor)

    records
    |> Enum.with_index(6)
    |> Enum.each(fn {record, index} ->
      assert String.length(record.child_name) == index
    end)
  end

  test """
       we can sort _descending_ by a left-joined field,
       even if renamed in the select clause
       """,
       c do
    child_schema = c.child_schema

    cursor =
      Cursor.new(
        from(t in c.trunk_schema,
          left_join: c in ^child_schema,
          on: t.child == c.id,
          select: %{t | child_name: c.name},
          order_by: [desc: c.name, desc: t.id]
        ),
        c.repo,
        nil,
        5
      )

    {records, cursor} = Cursor.next(cursor)

    records
    |> Enum.with_index(0)
    |> Enum.each(fn {record, index} ->
      assert String.length(record.child_name) == 20 - index
    end)

    {records, _cursor} = Cursor.next(cursor)

    records
    |> Enum.with_index(5)
    |> Enum.each(fn {record, index} ->
      assert String.length(record.child_name) == 20 - index
    end)
  end
end
