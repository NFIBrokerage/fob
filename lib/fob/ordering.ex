defmodule Fob.Ordering do
  @moduledoc false

  # helper functions and data structures for dealing with order_by clauses
  # in a query

  alias Ecto.Query
  import Ecto.Query
  require Fob.FragmentBuilder

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
         {direction, {:fragment, [], _} = f},
         query
       ) do
    table =
      Macro.prewalk(f, nil, fn x, acc ->
        case x do
          {:&, [], [t]} when is_integer(t) ->
            {x, t}

          _ ->
            {x, acc}
        end
      end)
      |> elem(1)

    column =
      query.select.expr
      |> Macro.prewalk(nil, fn x, acc ->
        case x do
          {a, ^f} when is_atom(a) ->
            {x, a}

          _ ->
            {x, acc}
        end
      end)
      |> elem(1)

    field_or_alias =
      Fob.FragmentBuilder.build_from_existing(
        [{t, table}],
        f,
        []
      )

    %__MODULE__{
      direction: direction,
      column: column,
      table: table,
      field_or_alias: field_or_alias
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
