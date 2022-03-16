defmodule Fob.FragmentCastingTest do
  use Fob.RepoCase

  @moduledoc """
  Tests that the Fob.between_bounds/3 function works as expected and respects
  nils
  """
  @moduledoc since: "0.2.0"

  alias Ecto.Multi
  alias Fob.Cursor

  setup do
    [schema: ChooseFieldSchema, repo: Fob.Repo]
  end

  setup c do
    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, c.schema.seed())
    |> c.repo.transaction()

    import ChooseFieldSchema, only: [date: 1]

    query =
      from t in c.schema,
        order_by: [desc: date(t), asc: :id],
        select_merge: %{date: date(t)}

    [query: query]
  end

  test "the dataset is fetched in the expected order", c do
    cursor = Cursor.new(c.query, c.repo, nil, 5)

    assert run_cursor(cursor) |> ids() == c.repo.all(c.query) |> ids()
  end

  test "next pages may be fetched even when the page break value is an ISO8601 date",
       c do
    expected_ids = c.query |> c.repo.all() |> ids()

    records = Fob.next_page(c.query, nil, 6) |> c.repo.all()
    assert records |> ids() == Enum.slice(expected_ids, 0..5)
    page_breaks = Fob.page_breaks(c.query, records |> List.last())

    records = Fob.next_page(c.query, page_breaks, 3) |> c.repo.all()
    assert records |> ids() == Enum.slice(expected_ids, 6..8)

    page_breaks =
      Fob.page_breaks(c.query, records |> List.last())
      |> update_in([Access.at(0), Access.key(:value)], fn %Date{} = date ->
        Date.to_iso8601(date)
      end)

    records = Fob.next_page(c.query, page_breaks, 3) |> c.repo.all()
    assert records |> ids() == Enum.slice(expected_ids, 9..11)
  end

  defp run_cursor(cursor, acc \\ []) do
    case Cursor.next(cursor) do
      {[], _cursor} -> acc
      {records, cursor} -> run_cursor(cursor, acc ++ records)
    end
  end

  defp ids(records), do: Enum.map(records, & &1.id)
end
