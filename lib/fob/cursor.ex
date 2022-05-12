defmodule Fob.Cursor do
  @moduledoc """
  A cursor data structure that can be used to fetch the next pages

  The cursor data structure is somewhat similar to a `Stream` except that it
  cannot wrap a stateful process and does not require any life-cycle hooks.
  The next pages of data can be fetched by calling `next/1` successively,
  passing in the updated `t:t/0` data structure each time.

  ## Examples

      iex> import Ecto.Query, only: [order_by: 2]
      iex> cursor = Fob.Cursor.new(order_by(MyApp.Schema, asc: :id), MyApp.Repo, nil, 3)
      #Fob.Cursor<...>
      iex> {_records, cursor} = Fob.Cursor.next(cursor)
      {[%{id: 1}, %{id: 2}, %{id: 3}], #Fob.Cursor<...>}
      iex> {_records, cursor} = Fob.Cursor.next(cursor)
      {[%{id: 4}, %{id: 5}, %{id: 6}], #Fob.Cursor<...>}
      iex> {_records, cursor} = Fob.Cursor.split(cursor, 2)
      {[%{id: 7}, %{id: 8}, %{id: 9}, %{id: 10}, %{id: 11}, %{id: 12}], #Fob.Cursor<...>}
  """

  if Version.match?(System.version(), ">= 1.8.0") do
    @derive {Inspect, only: []}
  end

  @typedoc """
  A data structure representing a position in a data set

  Cursors are immutable data structures that do not spawn or interact with
  processes.
  """
  @opaque t :: %__MODULE__{
            query: Ecto.Query.t(),
            repo: Ecto.Repo.t(),
            page_size: pos_integer(),
            page_breaks: [Fob.PageBreak.t()]
          }

  defstruct [:query, :repo, :page_size, :page_breaks]

  @doc """
  Creates a new cursor

  Pass `nil` as `page_breaks` to start at the beginning of the data set
  (ordered by whatever ordering conditions are on the queryable).
  """
  @spec new(
          Ecto.Queryable.t(),
          Ecto.Repo.t(),
          [Fob.PageBreak.t()] | nil,
          pos_integer()
        ) ::
          t()
  def new(queryable, repo, page_breaks, page_size)
      when is_integer(page_size) and page_size > 0 do
    %__MODULE__{
      query: Ecto.Queryable.to_query(queryable),
      repo: repo,
      page_breaks: page_breaks,
      page_size: page_size
    }
  end

  @doc """
  Fetches the next set of records and returns the next cursor

  If the underlying table doesn't change, calling `next/1` repeatedly
  will give the same records. The returned `cursor` can be used to get
  the next page of records.
  """
  @spec next(cursor :: t()) :: {records :: [map()], cursor :: t()}
  def next(%__MODULE__{} = cursor), do: split(cursor, 1)

  @doc """
  Fetches `count` next pages and returns the next cursor

  For reference: `next/1` is implemented as `split(cursor, 1)`.
  """
  @spec split(cursor :: t(), count :: non_neg_integer()) ::
          {records :: [map()], cursor :: t()}
  def split(%__MODULE__{} = cursor, count) when is_integer(count) do
    do_split(cursor, count, _acc = [])
  end

  defp do_split(cursor, count, acc)

  defp do_split(cursor, 0, acc), do: {acc |> finalize_acc(), cursor}

  # YARD figure out how to test this
  # chaps-ignore-start
  defp do_split(%__MODULE__{page_breaks: :halt} = cursor, _count, acc) do
    {acc |> finalize_acc(), cursor}
  end

  # chaps-ignore-stop

  defp do_split(cursor, count, acc) do
    {records, new_cursor} = source(cursor)

    do_split(new_cursor, count - 1, [records | acc])
  end

  defp source(cursor) do
    records =
      cursor.repo.all(
        Fob.next_page(cursor.query, cursor.page_breaks, cursor.page_size),
        []
      )

    {records, update_page_breaks(cursor, List.last(records))}
  end

  defp update_page_breaks(%__MODULE__{} = cursor, record) do
    page_breaks = Fob.page_breaks(cursor.query, record) || :halt

    %__MODULE__{cursor | page_breaks: page_breaks}
  end

  defp finalize_acc(acc), do: acc |> Enum.reverse() |> List.flatten()
end
