defmodule Fob.FragmentBuilderTest do
  use ExUnit.Case

  import Ecto.Query
  import Ecto.Query
  require Fob.FragmentBuilder

  test "fragement builder builds dynamic query" do
    query =
      from(
        s in "schema",
        as: :s,
        select: %{
          virtual_column: fragment("(? % 2)", s.id)
        },
        order_by: [asc: fragment("(? % 2)", s.id)]
      )

    %{expr: [{_direction, frag}]} = hd(query.order_bys)

    dyn = Fob.FragmentBuilder.build_from_existing([s: s], frag)

    assert %Ecto.Query.DynamicExpr{} = dyn
  end
end
