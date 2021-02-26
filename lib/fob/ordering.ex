defmodule Fob.Ordering do
  @moduledoc false

  # helper functions and data structures for dealing with order_by clauses
  # in a query

  alias Ecto.Query

  @type t :: %__MODULE__{
          table: non_neg_integer(),
          column: atom(),
          direction: :asc | :desc
        }

  defstruct ~w[table column direction]a

  @spec config(%Query{}) :: [t()]
  def config(%Query{order_bys: orderings}) do
    Enum.flat_map(orderings, fn %Query.QueryExpr{expr: exprs} ->
      config_from_ordering_expressions(exprs)
    end)
  end

  defp config_from_ordering_expressions(exprs) when is_list(exprs) do
    Enum.map(exprs, &config_from_ordering_expressions/1)
  end

  defp config_from_ordering_expressions(
         {direction, {{:., _, [{:&, _, [table]}, column]}, _, _}}
       ) do
    %__MODULE__{
      direction: direction,
      column: column,
      table: table
    }
  end

  @spec columns(%Query{}) :: [atom()]
  def columns(%Query{} = query) do
    query
    |> config()
    |> Enum.map(& &1.column)
    |> Enum.uniq()
  end

  # this mapping can help translate between the columns returned by config/1
  # into what will be on the records, so it's useful for fetching values for
  # page breaks
  @spec selection_mapping(%Query{}) :: %{atom() => atom()}
  def selection_mapping(%Query{
        select: %Query.SelectExpr{
          expr: {:%{}, _, [{:|, _, [{:&, _, [0]}, merges]}]}
        }
      }) do
    Enum.into(merges, %{}, fn {toplevel_name,
                               {{:., _, [{:&, _, _table}, name_in_table]}, _, _}} ->
      {name_in_table, toplevel_name}
    end)
  end

  def selection_mapping(%Query{}), do: %{}
end
