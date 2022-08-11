defmodule Fob.Ordering do
  @moduledoc false

  # helper functions and data structures for dealing with order_by clauses
  # in a query

  alias Ecto.Query
  alias Fob.FragmentBuilder
  require Fob.FragmentBuilder

  @typep table :: nil | non_neg_integer()
  @typep expr :: Macro.t()

  @type t :: %__MODULE__{
          table: table(),
          column: atom(),
          direction: :asc | :desc,
          maybe_expression: nil | expr()
        }

  defstruct ~w[table column direction maybe_expression]a

  @spec config(%Query{}) :: [t()]
  def config(%Query{order_bys: orderings} = query) do
    Enum.flat_map(orderings, fn %Query.QueryExpr{expr: exprs} ->
      config_from_ordering_expressions(exprs, query)
    end)
  end

  defp config_from_ordering_expressions(exprs, query) when is_list(exprs) do
    Enum.map(exprs, &config_from_ordering_expressions(&1, query))
  end

  defp config_from_ordering_expressions(
         {direction, {{:., _, [{:&, _, [table]}, column]}, _, _}},
         _
       ) do
    %__MODULE__{
      direction: direction,
      column: column,
      table: table,
      maybe_expression: nil
    }
  end

  defp config_from_ordering_expressions(
         {direction, {:fragment, [], _} = frag},
         query
       ) do
    table = FragmentBuilder.table_for_fragment(frag)

    column = FragmentBuilder.column_for_query_fragment(frag, query)

    dyn_expression =
      Fob.FragmentBuilder.build_from_existing(
        [{t, table}],
        frag
      )

    %__MODULE__{
      direction: direction,
      column: column,
      table: table,
      maybe_expression: dyn_expression
    }
  end

  @spec columns(%Query{}) :: [{table(), atom(), any()}]
  def columns(%Query{} = query) do
    query
    |> config()
    |> Enum.map(&{&1.table, &1.column})
    |> Enum.uniq()
  end

  # this mapping can help translate between the columns returned by config/1
  # into what will be on the records, so it's useful for fetching values for
  # page breaks
  @spec selection_mapping(%Query{}) :: %{{table(), atom()} => atom()}
  def selection_mapping(%Query{
        select: %Query.SelectExpr{
          expr: {:%{}, _, [{:|, _, [{:&, _, [0]}, merges]}]}
        }
      }) do
    Enum.reduce(merges, %{}, fn
      {toplevel_name, {{:., _, [{:&, _, [table]}, name_in_table]}, _, _}},
      acc ->
        Map.put(acc, {table, name_in_table}, toplevel_name)

      {_toplevel_name, _ast_expr}, acc ->
        acc
    end)
  end

  def selection_mapping(%Query{}), do: %{}

  @doc since: "0.2.0"
  @spec opposite(atom()) :: atom()
  def opposite(:asc), do: :desc
  def opposite(:asc_nulls_first), do: :desc_nulls_last
  def opposite(:asc_nulls_last), do: :desc_nulls_first
  def opposite(:desc), do: :asc
  def opposite(:desc_nulls_first), do: :asc_nulls_last
  def opposite(:desc_nulls_last), do: :asc_nulls_first
end
