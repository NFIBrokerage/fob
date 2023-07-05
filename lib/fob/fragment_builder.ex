defmodule Fob.FragmentBuilder do
  @moduledoc false

  @spec build([Macro.t()], Macro.t(), Macro.t(), Macro.Env.t()) :: Macro.t()
  def build(binding, expr, params, env) do
    is_ecto_greater_than_3_9_1 =
      case :application.get_key(:ecto, :vsn) do
        {:ok, version} ->
          version
          |> to_string()
          |> Version.match?(">= 3.9.1")

        _ ->
          false
      end

    quote do
      %Ecto.Query.DynamicExpr{
        fun: fn query ->
          _ = query

          if unquote(is_ecto_greater_than_3_9_1) do
            {unquote(expr), unquote(params), [], []}
          else
            {unquote(expr), unquote(params), []}
          end
        end,
        binding: unquote(Macro.escape(binding)),
        file: unquote(env.file),
        line: unquote(env.line)
      }
    end
  end

  defmacro build_from_existing(binding \\ [], expr) do
    build(binding, expr, [], __CALLER__)
  end

  def table_for_fragment({:fragment, [], _} = frag) do
    Macro.prewalk(frag, nil, fn ast, acc ->
      case ast do
        {:&, [], [table_idx]} when is_integer(table_idx) ->
          {ast, table_idx}

        _ ->
          {ast, acc}
      end
    end)
    |> elem(1)
  end

  def column_for_query_fragment(
        {:fragment, [], _} = frag,
        %Ecto.Query{} = query
      ) do
    query.select.expr
    |> Macro.prewalk(nil, fn ast, acc ->
      case ast do
        {virtual_column, ^frag} when is_atom(virtual_column) ->
          {ast, virtual_column}

        _ ->
          {ast, acc}
      end
    end)
    |> elem(1)
  end

  def columns_for_fragment({:fragment, [], _} = frag) do
    Macro.prewalk(frag, [], fn ast, acc ->
      case ast do
        # all "columns" access with a `.`, I think this will be just the
        # primary table in the query from the `[0]`
        {:., [], [{:&, [], [0]}, column]} when is_atom(column) ->
          {ast, [column | acc]}

        _ ->
          {ast, acc}
      end
    end)
    |> elem(1)
  end
end
