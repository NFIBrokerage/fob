defmodule Fob.PageBreakComparisonTest do
  use Fob.RepoCase

  @moduledoc false

  # Tests that the Fob.PageBreak.compare/2 function works as expected and respects
  # nils

  # Also tests the expand_space/4 function to ensure that it properly expands
  # the bounds of a page-break space.
  # @moduledoc since: "0.2.0"

  alias Ecto.Multi
  alias Fob.PageBreak

  setup do
    [schema: TieBreakerSchema, repo: Fob.Repo]
  end

  setup c do
    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, c.schema.seed())
    |> c.repo.transaction()

    :ok
  end

  test "compare/3 says that the start of the dataset comes before the end", c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]
    all_records = c.repo.all(query)

    for n <- 1..(length(all_records) - 1) do
      prior_record = Fob.page_breaks(query, all_records |> Enum.at(n - 1))
      record = Fob.page_breaks(query, all_records |> Enum.at(n))

      assert PageBreak.compare(prior_record, record, query) == :lt
    end

    all_records = Enum.reverse(all_records)

    for n <- 1..(length(all_records) - 1) do
      prior_record = Fob.page_breaks(query, all_records |> Enum.at(n - 1))
      record = Fob.page_breaks(query, all_records |> Enum.at(n))

      assert PageBreak.compare(prior_record, record, query) == :gt
    end
  end

  test "expand_space/4 properly expands a space of page-break bounds", c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]
    all_records = c.repo.all(query)
    first = Fob.page_breaks(query, Enum.at(all_records, 0))
    second = Fob.page_breaks(query, Enum.at(all_records, 1))
    last = Fob.page_breaks(query, Enum.at(all_records, -1))
    next_to_last = Fob.page_breaks(query, Enum.at(all_records, -2))

    assert {^first, ^last} = PageBreak.expand_space(second, last, first, query)

    assert {^first, ^last} =
             PageBreak.expand_space(first, next_to_last, last, query)

    assert {^first, ^last} = PageBreak.expand_space(first, last, second, query)

    assert {^first, ^last} =
             PageBreak.expand_space(first, last, next_to_last, query)
  end
end
