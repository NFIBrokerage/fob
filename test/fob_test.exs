defmodule FobTest do
  use ExUnit.Case

  test ":infinity page-size does not affect the query" do
    assert Fob.next_page(Foo, nil, :infinity) == Foo
  end
end
