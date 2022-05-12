defmodule Fob do
  @moduledoc """
  A keyset pagination library for Ecto queries

  Keyset pagination works by filtering a data set with `Ecto.Query.where/3`s
  rather than `Ecto.Query.offset/3`.

  Fob requires that any queryables are ordered by a unique column as the last
  ordering condition. Other non-unique columns may be ordered by as well, but
  the last `Ecto.Query.order_by/3` must be unique.
  """

  alias Fob.{Ordering, PageBreak}

  import Ecto.Query

  @ascending ~w[asc asc_nulls_first asc_nulls_last]a
  @descending ~w[desc desc_nulls_first desc_nulls_last]a

  @doc """
  Limits an `Ecto.Queryable` to the next page of data

  `page_breaks` are used to add `Ecto.Query.where/3` filters to the query which
  limit the query to the next page. `page_size` translates to a
  `Ecto.Query.limit/2`.
  """
  @doc since: "0.1.0"
  @spec next_page(
          Ecto.Queryable.t(),
          [PageBreak.t()] | nil,
          pos_integer() | :infinity
        ) ::
          Ecto.Query.t()
  def next_page(queryable, page_breaks, page_size)

  def next_page(queryable, page_breaks, page_size)
      when page_breaks == nil or page_breaks == [] do
    apply_limit(queryable, page_size)
  end

  def next_page(queryable, [_ | _] = page_breaks, page_size) do
    query = Ecto.Queryable.to_query(queryable)
    page_breaks = PageBreak.add_query_info(page_breaks, query)

    query
    |> route_keyset_comparison(page_breaks, :strict)
    |> apply_limit(page_size)
  end

  defp apply_limit(queryable, :infinity), do: queryable

  defp apply_limit(queryable, page_size) do
    limit(queryable, ^page_size)
  end

  defp route_keyset_comparison(routeable_page_break, acc) do
    case routeable_page_break do
      {page_break, nil} ->
        apply_keyset_comparison_field(page_break, acc)

      {page_break, expr} ->
        apply_keyset_comparison_expression(page_break, expr, acc)
    end
  end

  defp route_keyset_comparison(
         %Ecto.Query{} = query,
         nil = _page_breaks,
         _comparison_strictness
       ) do
    query
  end

  defp route_keyset_comparison(
         %Ecto.Query{} = query,
         [_ | _] = page_breaks,
         comparison_strictness
       ) do
    [id_break | remaining_breaks] = Enum.reverse(page_breaks)

    initial_acc = apply_basic_comparison(id_break, comparison_strictness)

    where_clause =
      remaining_breaks
      |> PageBreak.wrap_to_routeable(query)
      |> Enum.reduce(initial_acc, &route_keyset_comparison/2)

    where(query, ^where_clause)
  end

  defp apply_keyset_comparison_field(page_break, acc)

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: direction,
           value: nil,
           table: table,
           column: column
         },
         acc
       )
       when direction in [:asc, :asc_nulls_last, :desc_nulls_last] do
    dynamic([{t, table}], field(t, ^column) |> is_nil() and ^acc)
  end

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: direction,
           value: nil,
           table: table,
           column: column
         },
         acc
       )
       when direction in [:desc, :desc_nulls_first, :asc_nulls_first] do
    dynamic(
      [{t, table}],
      not is_nil(field(t, ^column)) or
        (field(t, ^column) |> is_nil() and ^acc)
    )
  end

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: direction,
           value: value,
           table: table,
           column: column
         },
         acc
       )
       when direction in [:asc, :asc_nulls_last] do
    dynamic(
      [{t, table}],
      field(t, ^column) > ^value or field(t, ^column) |> is_nil() or
        (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: :asc_nulls_first,
           value: value,
           table: table,
           column: column
         },
         acc
       ) do
    dynamic(
      [{t, table}],
      field(t, ^column) > ^value or (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: direction,
           value: value,
           table: table,
           column: column
         },
         acc
       )
       when direction in [:desc, :desc_nulls_first] do
    dynamic(
      [{t, table}],
      field(t, ^column) < ^value or (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison_field(
         %PageBreak{
           direction: :desc_nulls_last,
           value: value,
           table: table,
           column: column
         },
         acc
       ) do
    dynamic(
      [{t, table}],
      field(t, ^column) < ^value or field(t, ^column) |> is_nil() or
        (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: direction,
           value: nil
         },
         expression,
         acc
       )
       when direction in [:asc, :asc_nulls_last, :desc_nulls_last] do
    dynamic(^expression |> is_nil() and ^acc)
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: direction,
           value: nil
         },
         expression,
         acc
       )
       when direction in [:desc, :desc_nulls_first, :asc_nulls_first] do
    dynamic(
      not is_nil(^expression) or
        (^expression |> is_nil() and ^acc)
    )
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: direction,
           value: value
         },
         expression,
         acc
       )
       when direction in [:asc, :asc_nulls_last] do
    dynamic(
      ^expression > ^value or ^expression |> is_nil() or
        (^expression == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: :asc_nulls_first,
           value: value
         },
         expression,
         acc
       ) do
    dynamic(^expression > ^value or (^expression == ^value and ^acc))
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: direction,
           value: value
         },
         expression,
         acc
       )
       when direction in [:desc, :desc_nulls_first] do
    dynamic(^expression < ^value or (^expression == ^value and ^acc))
  end

  defp apply_keyset_comparison_expression(
         %PageBreak{
           direction: :desc_nulls_last,
           value: value
         },
         expression,
         acc
       ) do
    dynamic(
      ^expression < ^value or ^expression |> is_nil() or
        (^expression == ^value and ^acc)
    )
  end

  # this function is used for comparing the ID page-break, which is a break
  # that describes the values on the primary key of the table
  # this assumes that primary key values must not be nil
  defp apply_basic_comparison(page_break, comparison_strictness)

  defp apply_basic_comparison(
         %PageBreak{
           direction: direction,
           table: table,
           value: value,
           column: column
         },
         :strict
       )
       when direction in @ascending do
    dynamic([{t, table}], field(t, ^column) > ^value)
  end

  defp apply_basic_comparison(
         %PageBreak{
           direction: direction,
           table: table,
           value: value,
           column: column
         },
         :lenient
       )
       when direction in @ascending do
    dynamic([{t, table}], field(t, ^column) >= ^value)
  end

  defp apply_basic_comparison(
         %PageBreak{
           direction: direction,
           table: table,
           value: value,
           column: column
         },
         :strict
       )
       when direction in @descending do
    dynamic([{t, table}], field(t, ^column) < ^value)
  end

  defp apply_basic_comparison(
         %PageBreak{
           direction: direction,
           table: table,
           value: value,
           column: column
         },
         :lenient
       )
       when direction in @descending do
    dynamic([{t, table}], field(t, ^column) <= ^value)
  end

  @doc """
  Returns the page breaks for a record

  The query does not need to be limited by `next_page/3` or
  `between_bounds/3`: the query only needs to have the
  `Ecto.Query.order_by/3`s used in the query to get the record.

  ## Examples

      iex> records = MyApp.Repo.all(Fob.next_page(query, current_page_breaks, page_size))
      iex> next_page_breaks = Fob.page_breaks(query, List.last(records))
  """
  @doc since: "0.1.0"
  @spec page_breaks(Ecto.Queryable.t(), record :: map() | nil) ::
          [PageBreak.t()] | nil
  def page_breaks(_queryable, nil), do: nil

  def page_breaks(queryable, record) do
    query = Ecto.Queryable.to_query(queryable)
    selection_mapping = Ordering.selection_mapping(query)

    query
    |> Ordering.columns()
    |> Enum.map(fn {table, name} ->
      key = Map.get(selection_mapping, {table, name}, name)

      %PageBreak{
        column: name,
        value: get_in(record, [Access.key(key)])
      }
    end)
  end

  @doc """
  Limits a queryable to return records between two page break boundaries
  """
  @doc since: "0.1.0"
  @spec between_bounds(
          Ecto.Queryable.t(),
          [PageBreak.t()] | nil,
          [PageBreak.t()] | nil
        ) ::
          Ecto.Query.t()
  def between_bounds(queryable, start, stop)

  def between_bounds(queryable, start, stop) do
    query = Ecto.Queryable.to_query(queryable)
    start = start |> PageBreak.add_query_info(query)
    stop = stop |> PageBreak.add_query_info(query) |> reverse()

    query
    |> route_keyset_comparison(start, :lenient)
    |> route_keyset_comparison(stop, :lenient)
  end

  defp reverse(nil), do: nil

  defp reverse(page_breaks) do
    Enum.map(page_breaks, fn page_break ->
      update_in(page_break.direction, &Ordering.opposite/1)
    end)
  end
end
