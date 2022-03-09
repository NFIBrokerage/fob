defmodule Fob.FragmentBuilder do
  @moduledoc false
  # Wyno cover? 
  # chaps-ignore-start
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

  defmacro build_from_existing(binding \\ [], expr, params) do
    build(binding, expr, params, __CALLER__)
  end

  # chaps-ignore-start
end
