defmodule Fob.PageBreak do
  @moduledoc false

  alias Fob.Ordering

  # a data structure for describing where in a dataset we have drawn a page
  # line

  defstruct ~w[column value table direction]a

  def add_query_info(page_breaks, %Ecto.Query{} = query)
      when is_list(page_breaks) do
    ordering_config = Ordering.config(query)

    Enum.map(page_breaks, &add_query_info(&1, ordering_config))
  end

  def add_query_info(%{column: column} = page_break, ordering_config) do
    order = Enum.find(ordering_config, fn order -> column == order.column end)

    %__MODULE__{page_break | table: order.table, direction: order.direction}
  end
end
