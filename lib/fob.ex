defmodule Fob do
  @moduledoc """
  A keyset pagination library for Ecto queries
  """

  @doc """
  Wraps a queryable in a Stream

  Suitable for fetching pages with the Stream API in the standard library,
  e.g.: `Stream.take/2`
  """
  @doc since: "0.1.0"
  @spec stream(queryable :: Ecto.Queryable.t(), page_size :: pos_integer()) ::
          stream :: Enumerable.t()
  def stream(queryable, page_size \\ 45) do
    query = Ecto.Queryable.to_query(queryable)

    Stream.unfold(
      %Fob.Stream{query: query, page_size: page_size},
      &Fob.Stream.next/2
    )
  end
end
