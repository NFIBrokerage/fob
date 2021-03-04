defmodule Fob.PageBreak do
  @moduledoc false

  alias Fob.Ordering

  # a data structure for describing where in a dataset we have drawn a page
  # line

  @ascending ~w[asc asc_nulls_first asc_nulls_last]a

  # N.B.
  # :asc == :asc_nulls_last
  # :desc == :desc_nulls_first

  defstruct ~w[column value table direction]a

  def add_query_info(nil, _), do: nil

  def add_query_info(page_breaks, %Ecto.Query{} = query)
      when is_list(page_breaks) do
    ordering_config = Ordering.config(query)

    Enum.map(page_breaks, &add_query_info(&1, ordering_config))
  end

  def add_query_info(%{column: column} = page_break, ordering_config) do
    order = Enum.find(ordering_config, fn order -> column == order.column end)

    %__MODULE__{page_break | table: order.table, direction: order.direction}
  end

  @doc since: "0.2.0"
  def compare(a, b, query) when is_list(a) and is_list(b) do
    compare(add_query_info(a, query), add_query_info(b, query))
  end

  def compare(a, b)

  def compare(a, b) when is_list(a) and is_list(b) and length(a) == length(b) do
    Enum.zip(a, b)
    |> Enum.map(fn {a, b} -> compare(a, b) end)
    |> Enum.find(:eq, fn comparison -> comparison != :eq end)
  end

  def compare(%__MODULE__{value: a, direction: direction}, %__MODULE__{
        value: b,
        direction: direction
      })
      when is_atom(direction) and direction != nil do
    _compare(a, b, direction)
  end

  defp _compare(a, b, direction)

  defp _compare(value, value, _direction), do: :eq

  defp _compare(a, b, direction) when a != nil and b != nil do
    comparator = if direction in @ascending, do: &>/2, else: &</2

    if comparator.(a, b), do: :gt, else: :lt
  end

  # nil is either infinity or -infinity depending on the direction
  defp _compare(nil, _b, direction)
       when direction in ~w[asc_nulls_first desc desc_nulls_first]a,
       do: :lt

  defp _compare(nil, _b, direction)
       when direction in ~w[asc asc_nulls_last desc_nulls_last]a,
       do: :gt

  defp _compare(_a, nil, direction)
       when direction in ~w[asc_nulls_first desc desc_nulls_first]a,
       do: :gt

  defp _compare(_a, nil, direction)
       when direction in ~w[asc asc_nulls_last desc_nulls_last]a,
       do: :lt
end
