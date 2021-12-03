defmodule Fob do
  @moduledoc """
  A keyset pagination library for Ecto queries
  """

  alias Fob.{Ordering, PageBreak}

  import Ecto.Query

  @ascending ~w[asc asc_nulls_first asc_nulls_last]a
  @descending ~w[desc desc_nulls_first desc_nulls_last]a

  @doc since: "0.1.0"
  @spec next_page(
          Ecto.Queryable.t(),
          [PageBreak.t()],
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
    |> apply_keyset_comparison(page_breaks, :strict)
    |> apply_limit(page_size)
  end

  defp apply_limit(queryable, :infinity), do: queryable

  defp apply_limit(queryable, page_size) do
    limit(queryable, ^page_size)
  end

  defp apply_keyset_comparison(
         %Ecto.Query{} = query,
         nil = _page_breaks,
         _comparison_strictness
       ) do
    query
  end

  defp apply_keyset_comparison(
         %Ecto.Query{} = query,
         [_ | _] = page_breaks,
         comparison_strictness
       ) do
    [id_break | remaining_breaks] = Enum.reverse(page_breaks)

    initial_acc = apply_basic_comparison(id_break, comparison_strictness)

    where_clause =
      Enum.reduce(remaining_breaks, initial_acc, &apply_keyset_comparison/2)

    where(query, ^where_clause)
  end

  defp apply_keyset_comparison(page_break, accumulator)

  # --- value is nil

  defp apply_keyset_comparison(
         %PageBreak{
           direction: direction,
           column: column,
           table: table,
           value: nil
         },
         acc
       )
       when direction in [:asc, :asc_nulls_last, :desc_nulls_last] do
    dynamic([{t, table}], field(t, ^column) |> is_nil() and ^acc)
  end

  defp apply_keyset_comparison(
         %PageBreak{
           direction: direction,
           column: column,
           table: table,
           value: nil
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

  # --- value is non-nil

  defp apply_keyset_comparison(
         %PageBreak{
           direction: direction,
           column: column,
           table: table,
           value: value
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

  defp apply_keyset_comparison(
         %PageBreak{
           direction: :asc_nulls_first,
           column: column,
           table: table,
           value: value
         },
         acc
       ) do
    dynamic(
      [{t, table}],
      field(t, ^column) > ^value or (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison(
         %PageBreak{
           direction: direction,
           column: column,
           table: table,
           value: value
         },
         acc
       )
       when direction in [:desc, :desc_nulls_first] do
    dynamic(
      [{t, table}],
      field(t, ^column) < ^value or (field(t, ^column) == ^value and ^acc)
    )
  end

  defp apply_keyset_comparison(
         %PageBreak{
           direction: :desc_nulls_last,
           column: column,
           table: table,
           value: value
         },
         acc
       ) do
    dynamic(
      [{t, table}],
      field(t, ^column) < ^value or field(t, ^column) |> is_nil() or
        (field(t, ^column) == ^value and ^acc)
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

  @doc since: "0.1.0"
  @spec page_breaks(Ecto.Queryable.t(), record :: map() | nil) ::
          [PageBreak.t()] | nil
  def page_breaks(_queryable, nil), do: nil

  def page_breaks(queryable, record) do
    query = Ecto.Queryable.to_query(queryable)
    selection_mapping = Ordering.selection_mapping(query)

    query
    |> Ordering.columns()
    |> Enum.map(fn column ->
      key = Map.get(selection_mapping, column, column)

      %PageBreak{column: column, value: get_in(record, [Access.key(key)])}
    end)
  end

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
    |> apply_keyset_comparison(start, :lenient)
    |> apply_keyset_comparison(stop, :lenient)
  end

  defp reverse(nil), do: nil

  defp reverse(page_breaks) do
    Enum.map(page_breaks, fn page_break ->
      %PageBreak{
        page_break
        | direction: Ordering.opposite(page_break.direction)
      }
    end)
  end
end
