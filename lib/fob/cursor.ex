defmodule Fob.Cursor do
  @moduledoc """
  TODO
  """

  if Version.match?(System.version(), ">= 1.8.0") do
    @derive {Inspect, only: []}
  end

  @type t :: %__MODULE__{
          query: Ecto.Query.t(),
          repo: Ecto.Repo.t(),
          page_size: pos_integer(),
          page_breaks: Fob.page_breaks()
        }

  defstruct [:query, :repo, :page_size, :page_breaks]

  @spec new(Ecto.Queryable.t(), Ecto.Repo.t(), Fob.page_breaks(), pos_integer()) ::
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

  @spec next(cursor :: t()) :: {records :: [map()], cursor :: t()}
  def next(%__MODULE__{} = cursor), do: split(cursor, 1)

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
