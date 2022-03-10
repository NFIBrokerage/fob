defmodule Fob.FragmentBuilder do
  @moduledoc false
  @spec build([Macro.t()], Macro.t(), Macro.t(), Macro.Env.t()) :: Macro.t()
  def build(binding, expr, params, env) do
    quote do
      %Ecto.Query.DynamicExpr{
        fun: fn query ->
          {unquote(expr), unquote(params), []}
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
end
