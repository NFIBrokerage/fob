defmodule Fob.Ordering do
  @moduledoc false

  # helper functions and data structures for dealing with order_by clauses
  # in a query

  alias Ecto.Query
  import Ecto.Query

  @typep table :: nil | non_neg_integer()

  @type t :: %__MODULE__{
          table: table(),
          column: atom(),
          direction: :asc | :desc,
          field_or_alias: any()
        }

  defstruct ~w[table column direction field_or_alias]a

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
      field_or_alias: dynamic([{t, table}], field(t, ^column))
    }
  end

  defp config_from_ordering_expressions(
         {direction,
          {:fragment, [],
           [
             raw: _pre,
             expr: {{:., [], [{:&, [], [table]}, column]}, [], []},
             raw: _post
           ]}},
         _query
       ) do
    # this can be rebuild by the incoming or found via a Macro.prewalker + Enum.find
    # as well as the name of the virtual column
    a =
      dynamic(
        [{t, table}],
        fragment("(? % 2)", field(t, ^column))
      )

    %__MODULE__{
      direction: direction,
      column: :virtual_column,
      table: table,
      # this needs to be the select expression 
      field_or_alias: a
    }
  end

  defp config_from_ordering_expressions(
         {direction, {:fragment, [], [raw: virtual_column]}},
         _query
       )
       when is_binary(virtual_column) do
    %__MODULE__{
      direction: direction,
      column: String.to_existing_atom(virtual_column),
      table: nil,
      # this needs to be the select expression 
      field_or_alias: dynamic(coalesce(fragment("?", ^virtual_column), nil))
    }
  end

  @spec columns(%Query{}) :: [{table(), atom(), any()}]
  def columns(%Query{} = query) do
    query
    |> config()
    |> Enum.map(&{&1.table, &1.column, &1.field_or_alias})
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
    Map.new(merges, fn {toplevel_name,
                        {{:., _, [{:&, _, [table]}, name_in_table]}, _, _}} ->
      {{table, name_in_table}, toplevel_name}
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
