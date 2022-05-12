defmodule Fob.PageBreak do
  @moduledoc """
  Functions and types for operating on page break values
  """

  alias Fob.Ordering

  @ascending ~w[asc asc_nulls_first asc_nulls_last]a

  # N.B.
  # :asc == :asc_nulls_last
  # :desc == :desc_nulls_first

  @typedoc """
  A data structure for describing a position within an ordered data set
  """
  @type t :: %__MODULE__{}

  defstruct ~w[column value table direction]a

  @doc false
  def add_query_info(nil, _), do: nil

  def add_query_info(page_breaks, %Ecto.Query{} = query)
      when is_list(page_breaks) do
    ordering_config = Ordering.config(query)

    Enum.map(page_breaks, &add_query_info(&1, ordering_config, query))
  end

  @doc false
  def add_query_info(
        %{column: column, value: value} = page_break,
        ordering_config,
        query
      ) do
    order = Enum.find(ordering_config, fn order -> column == order.column end)
    casted_value = cast_type(query, column, value)

    %__MODULE__{
      page_break
      | table: order.table,
        direction: order.direction,
        value: casted_value
    }
  end

  @doc false
  def wrap_to_routeable(page_breaks, %Ecto.Query{} = query)
      when is_list(page_breaks) do
    ordering_config = Ordering.config(query)

    Enum.map(page_breaks, &wrap_to_routeable(&1, ordering_config))
  end

  def wrap_to_routeable(%{column: column} = page_break, ordering_config) do
    order = Enum.find(ordering_config, fn order -> column == order.column end)
    {page_break, order.maybe_expression}
  end

  defp cast_type(query, column, value) do
    with {_table_name, schema} <- query.from.source,
         true <- function_exported?(schema, :__changeset__, 0),
         %{^column => type} <- schema.__changeset__() do
      do_cast_type(type, value)
    else
      _ -> value
    end
  end

  @iso_8601_modules %{
    :date => Date,
    :time => Time,
    :naive_datetime => NaiveDateTime,
    :naive_datetime_usec => NaiveDateTime,
    :utc_datetime => DateTime,
    :utc_datetime_usec => DateTime
  }

  for {type, module} <- @iso_8601_modules do
    defp do_cast_type(unquote(type), string) when is_binary(string) do
      case unquote(module).from_iso8601(string) do
        {:ok, casted_value} ->
          casted_value

        # chaps-ignore-start
        _ ->
          string
          # chaps-ignore-stop
      end
    end
  end

  defp do_cast_type(_type, value), do: value

  @doc """
  Compares two page breaks given the ordering defined in the queryable

  Returns `:eq` if the two page breaks are equal, `:lt` if `a` is would come
  before `b` in the data set when queried, and `:gt` if `b` would come before
  `a`.
  """
  @doc since: "0.2.0"
  @spec compare([t()], [t()], Ecto.Queryable.t()) :: :lt | :eq | :gt
  def compare(a, b, query) when is_list(a) and is_list(b) do
    compare(add_query_info(a, query), add_query_info(b, query))
  end

  def compare(nil, _, _), do: :lt
  def compare(_, nil, _), do: :gt

  @doc false
  def compare(a, b)

  def compare(a, b) when is_list(a) and is_list(b) and length(a) == length(b) do
    Enum.zip(a, b)
    |> Enum.map(fn {a, b} -> compare(a, b) end)
    |> Enum.find(:eq, fn comparison -> comparison != :eq end)
  end

  def compare(%__MODULE__{value: a, direction: direction}, %__MODULE__{
        value: b,
        direction: direction
      })
      when is_atom(direction) and direction != nil do
    _compare(a, b, direction)
  end

  def compare(nil, _), do: :lt
  def compare(_, nil), do: :gt

  defp _compare(a, b, direction)

  defp _compare(value, value, _direction), do: :eq

  defp _compare(a, b, direction) when a != nil and b != nil do
    comparator = if direction in @ascending, do: &>/2, else: &</2

    if comparator.(a, b), do: :gt, else: :lt
  end

  # nil is either infinity or -infinity depending on the direction
  defp _compare(nil, _b, direction)
       when direction in ~w[asc_nulls_first desc desc_nulls_first]a,
       do: :lt

  defp _compare(nil, _b, direction)
       when direction in ~w[asc asc_nulls_last desc_nulls_last]a,
       do: :gt

  defp _compare(_a, nil, direction)
       when direction in ~w[asc_nulls_first desc desc_nulls_first]a,
       do: :gt

  defp _compare(_a, nil, direction)
       when direction in ~w[asc asc_nulls_last desc_nulls_last]a,
       do: :lt

  @doc """
  Expands the n-dimensional space occupied by a bound of page-breaks

  If one holds on to the page-breaks from the `start` and `stop` of a dataset
  (with `start` being the first record returned and `stop` being the last
  record of the most recently requested page; i.e. the cursor), they have
  the boundaries of the page-break-space for the `query`. It can be useful to
  be able to expand this space in the case of row insertions into the database.
  If an insertion comes in, one must compute its page-break values and compare
  those to the held `start` and `stop` page-break values.

  This function performs that comparison and returns a tuple of the new
  `start` and `stop`, where `proposed` could possibly replace the `start` or
  `stop` (or neither).
  """
  @doc since: "0.3.0"
  @spec expand_space(
          start :: [t()],
          stop :: [t()],
          proposed :: [t()],
          Ecto.Query.t()
        ) :: {new_start :: [t()], new_stop :: [t()]}
  def expand_space(start, stop, proposed, query) do
    new_start =
      if compare(proposed, start, query) == :lt, do: proposed, else: start

    new_stop =
      if compare(proposed, stop, query) == :gt, do: proposed, else: stop

    {new_start, new_stop}
  end
end
