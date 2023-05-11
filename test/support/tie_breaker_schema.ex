defmodule TieBreakerSchema do
  @moduledoc false
  # A schema in which records will share values with one another

  use Ecto.Schema

  schema "tie_breaker_schema" do
    field :date, :date
    field :naive_datetime, :naive_datetime
    field :naive_datetime_usec, :naive_datetime_usec
    field :utc_datetime, :utc_datetime
    field :utc_datetime_usec, :utc_datetime_usec
    field :name
  end

  def seed do
    t1 = random_time()
    t2 = random_time()

    [
      {~D[2020-12-15] |> DateTime.new!(t1, "Etc/UTC"), "a", 0},
      {~D[2020-12-15] |> DateTime.new!(t1, "Etc/UTC"), "a", 1},
      {~D[2020-12-15] |> DateTime.new!(t2, "Etc/UTC"), "a", 2},
      {~D[2020-12-15] |> DateTime.new!(t2, "Etc/UTC"), "a", 3},
      {~D[2020-12-15] |> DateTime.new!(t1, "Etc/UTC"), "b", 4},
      {~D[2020-12-15] |> DateTime.new!(t1, "Etc/UTC"), "b", 5},
      {~D[2020-12-15] |> DateTime.new!(t2, "Etc/UTC"), "b", 6},
      {~D[2020-12-15] |> DateTime.new!(t2), "b", 7},
      {~D[2020-12-15] |> DateTime.new!(random_time(), "Etc/UTC"), nil, 8},
      {~D[2020-12-15] |> DateTime.new!(random_time(), "Etc/UTC"), nil, 9},
      {~D[2020-12-17] |> DateTime.new!(random_time(), "Etc/UTC"), nil, 10},
      {~D[2020-12-17] |> DateTime.new!(random_time(), "Etc/UTC"), "b", 11},
      {~D[2020-12-17] |> DateTime.new!(random_time(), "Etc/UTC"), "b", 12},
      {~D[2020-12-17] |> DateTime.new!(random_time(), "Etc/UTC"), "c", 13},
      {~D[2020-12-17] |> DateTime.new!(random_time(), "Etc/UTC"), "c", 14},
      {nil, "c", 15},
      {nil, "c", 16},
      {nil, "c", 17},
      {nil, "c", 18},
      {nil, "c", 19}
    ]
    |> Enum.map(fn
      {nil, name, index} ->
        %{
          id: index,
          name: name,
          date: nil,
          naive_datetime: nil,
          utc_datetime: nil,
          utc_datetime_usec: nil
        }

      {datetime, name, index} ->
        %{
          id: index,
          name: name,
          date: DateTime.to_date(datetime),
          naive_datetime:
            DateTime.to_naive(DateTime.truncate(datetime, :second)),
          naive_datetime_usec: DateTime.to_naive(datetime),
          utc_datetime: DateTime.truncate(datetime, :second),
          utc_datetime_usec: datetime
        }
    end)
  end

  def random_time do
    r = &Enum.random(&1)

    Time.new!(
      _hour = r.(0..23),
      _min = r.(0..59),
      _sec = r.(0..59),
      _micro = r.(0..1_000_000)
    )
  end
end
