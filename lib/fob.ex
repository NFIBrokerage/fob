defmodule Fob do
  @moduledoc """
  A keyset pagination library for Ecto queries
  """

  alias Fob.{Ordering, PageBreak}

  import Ecto.Query

  @doc since: "0.1.0"
  @spec next_page(Ecto.Queryable.t(), [PageBreak.t()], pos_integer()) :: Ecto.Query.t()
  def next_page(queryable, page_breaks, page_size)

  def next_page(queryable, page_breaks, page_size) when page_breaks == nil or page_breaks == [] do
    limit(queryable, ^page_size)
  end

  def next_page(queryable, [_ | _] = page_breaks, page_size) do
    query = Ecto.Queryable.to_query(queryable)
    page_breaks = PageBreak.add_query_info(page_breaks, query)

    query
    |> apply_keyset_comparison(page_breaks)
    |> limit(^page_size)
  end

  defp apply_keyset_comparison(%Ecto.Query{} = query, [_ | _] = page_breaks) do
    [id_break | remaining_breaks] = Enum.reverse(page_breaks)

    initial_acc =
      case id_break do
        %PageBreak{direction: :asc, table: table, value: value, column: column} ->
          dynamic([{t, table}], field(t, ^column) > ^value)

        %PageBreak{direction: :desc, table: table, value: value, column: column} ->
          dynamic([{t, table}], field(t, ^column) < ^value)
      end

    where_clause =
      Enum.reduce(remaining_breaks, initial_acc, &apply_keyset_comparison/2)

    where(query, ^where_clause)
  end

  # --- value is nil

  defp apply_keyset_comparison(%PageBreak{direction: direction, column: column, table: table, value: nil}, acc) when direction in [:asc, :asc_nulls_last] do
    dynamic([{t, table}], field(t, ^column) |> is_nil() and ^acc)
  end

  defp apply_keyset_comparison(%PageBreak{direction: :asc_nulls_first, column: column, table: table, value: nil}, acc) do
    dynamic([{t, table}], field(t, ^column) > fragment("'-infinity'") or (field(t, ^column) |> is_nil() and ^acc))
  end

  defp apply_keyset_comparison(%PageBreak{direction: direction, column: column, table: table, value: nil}, acc) when direction in [:desc, :desc_nulls_first] do
    dynamic([{t, table}], field(t, ^column) < fragment("'infinity'") or (field(t, ^column) |> is_nil() and ^acc))
  end

  defp apply_keyset_comparison(%PageBreak{direction: :desc_nulls_last, column: column, table: table, value: nil}, acc) do
    dynamic([{t, table}], field(t, ^column) |> is_nil() and ^acc)
  end

  # --- value is non-nil

  defp apply_keyset_comparison(%PageBreak{direction: direction, column: column, table: table, value: value}, acc) when direction in [:asc, :asc_nulls_last] do
    dynamic([{t, table}], field(t, ^column) > ^value or field(t, ^column) |> is_nil() or (field(t, ^column) == ^value and ^acc))
  end

  defp apply_keyset_comparison(%PageBreak{direction: :asc_nulls_first, column: column, table: table, value: value}, acc) do
    dynamic([{t, table}], field(t, ^column) > ^value or (field(t, ^column) == ^value and ^acc))
  end

  defp apply_keyset_comparison(%PageBreak{direction: direction, column: column, table: table, value: value}, acc) when direction in [:desc, :desc_nulls_first] do
    dynamic([{t, table}], field(t, ^column) < ^value or (field(t, ^column) == ^value and ^acc))
  end

  defp apply_keyset_comparison(%PageBreak{direction: :desc_nulls_last, column: column, table: table, value: value}, acc) do
    dynamic([{t, table}], field(t, ^column) < ^value or field(t, ^column) |> is_nil() or (field(t, ^column) == ^value and ^acc))
  end

  @doc since: "0.1.0"
  @spec page_breaks(Ecto.Queryable.t(), record :: map() | nil) :: [PageBreak.t()] | nil
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
end
