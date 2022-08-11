defmodule Fob.ComputedSelectTest do
  use Fob.RepoCase
  alias Fob.Cursor
  alias Ecto.Multi

  describe "single table" do
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

    test "when selecting with computed query, we can get each page", c do
      cursor =
        Cursor.new(
          from(
            s in c.schema,
            select: %{
              id: s.id,
              computed_column: 1 >= 5
            },
            order_by: [asc: s.id]
          ),
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
  end

  describe "left join" do
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
            select: %{t | child_name: c.name, computed: c.id + t.id},
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
  end
end
