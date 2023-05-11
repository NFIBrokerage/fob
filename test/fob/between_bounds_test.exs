defmodule Fob.BetweenBoundsTest do
  use Fob.RepoCase

  @moduledoc false

  # Tests that the Fob.between_bounds/3 function works as expected and respects
  # nils

  # @moduledoc since: "0.2.0"

  alias Ecto.Multi
  import Fob, only: [between_bounds: 3, page_breaks: 2]

  setup do
    [schema: TieBreakerSchema, repo: Fob.Repo]
  end

  setup c do
    Multi.new()
    |> Multi.insert_all(:seeds, c.schema, c.schema.seed())
    |> c.repo.transaction()

    :ok
  end

  test "between_bounds/3 can return the entire dataset with nil page breaks",
       c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]
    all_records = c.repo.all(query)

    assert between_bounds(query, nil, nil) |> c.repo.all() == all_records
  end

  test "between_bounds/3 can return the entire dataset with book-end page-breaks",
       c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]
    all_records = c.repo.all(query)
    start = page_breaks(query, List.first(all_records))
    stop = page_breaks(query, List.last(all_records))

    assert between_bounds(query, start, stop) |> c.repo.all() == all_records
  end

  test "between_bounds/3 can return a subset of the entire dataset", c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]
    records = c.repo.all(query) |> Enum.slice(_start_at = 3, _count = 5)
    start = page_breaks(query, List.first(records))
    stop = page_breaks(query, List.last(records))

    assert between_bounds(query, start, stop) |> c.repo.all() == records
  end

  test "between_bounds/3 can return a single record when start and stop are equal",
       c do
    schema = c.schema
    query = from t in schema, order_by: [asc_nulls_last: :date, asc: :id]

    [record] =
      c.repo.all(query)
      |> Enum.slice(_start_at = 3, _count = 1)

    start = page_breaks(query, record)
    stop = page_breaks(query, record)

    assert between_bounds(query, start, stop) |> c.repo.all() == [record]
  end

  test "between_bounds/3 can return a single record when start and stop are equal and naive_datetime",
       c do
    schema = c.schema

    query =
      from t in schema, order_by: [asc_nulls_last: :naive_datetime, asc: :id]

    [record] =
      c.repo.all(query)
      |> Enum.slice(_start_at = 3, _count = 1)

    start = page_breaks(query, record)
    stop = page_breaks(query, record)

    assert between_bounds(query, start, stop) |> c.repo.all() == [record]
  end

  test "between_bounds/3 can return a single record when start and stop are equal and naive_datetime_usec",
       c do
    schema = c.schema

    query =
      from t in schema,
        order_by: [asc_nulls_last: :naive_datetime_usec, asc: :id]

    [record] =
      c.repo.all(query)
      |> Enum.slice(_start_at = 3, _count = 1)

    start = page_breaks(query, record)
    stop = page_breaks(query, record)

    assert between_bounds(query, start, stop) |> c.repo.all() == [record]
  end

  test "between_bounds/3 can return a single record when start and stop are equal and utc_datetime",
       c do
    schema = c.schema

    query =
      from t in schema, order_by: [asc_nulls_last: :utc_datetime, asc: :id]

    [record] =
      c.repo.all(query)
      |> Enum.slice(_start_at = 3, _count = 1)

    start = page_breaks(query, record)
    stop = page_breaks(query, record)

    assert between_bounds(query, start, stop) |> c.repo.all() == [record]
  end

  test "between_bounds/3 can return a single record when start and stop are equal and utc_datetime_usec",
       c do
    schema = c.schema

    query =
      from t in schema, order_by: [asc_nulls_last: :utc_datetime_usec, asc: :id]

    [record] =
      c.repo.all(query)
      |> Enum.slice(_start_at = 3, _count = 1)

    start = page_breaks(query, record)
    stop = page_breaks(query, record)

    assert between_bounds(query, start, stop) |> c.repo.all() ==
             [record]
  end
end
