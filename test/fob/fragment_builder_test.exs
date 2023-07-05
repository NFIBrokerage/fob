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

  test "fragement builder builds captures columns" do
    query =
      from(
        s in "schema",
        as: :s,
        left_join: s2 in "schema_2",
        as: :s2,
        select: %{
          virtual_column: fragment("(? % ? % ?)", s.id, s.next, s2.other)
        },
        order_by: [asc: fragment("(? % ? % ?)", s.id, s.next, s2.other)]
      )

    %{expr: [{_direction, frag}]} = hd(query.order_bys)

    columns = frag |> Fob.FragmentBuilder.columns_for_fragment() |> MapSet.new()
    assert MapSet.equal?(MapSet.new([:id, :next]), columns)
  end

  test "fragement builder builds captures empty columns" do
    query =
      from(
        s in "schema",
        as: :s,
        left_join: s2 in "schema_2",
        as: :s2,
        select: %{
          virtual_column: fragment("(5)")
        },
        order_by: [asc: fragment("(5)")]
      )

    %{expr: [{_direction, frag}]} = hd(query.order_bys)

    columns = frag |> Fob.FragmentBuilder.columns_for_fragment() |> MapSet.new()
    assert MapSet.equal?(MapSet.new(), columns)
  end
end
