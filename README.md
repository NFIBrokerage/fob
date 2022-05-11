# Fob

![Actions CI](https://github.com/NFIBrokerage/fob/workflows/Actions%20CI/badge.svg)

A minimalistic keyset pagination library for Ecto queries

**N.B.**: you probably don't want to use Fob. Fob makes a number of assumptions
about the queries passed to it, such as:

- each schema will have only one primary key
- each query must be ordered by at least the schema's primary key
- the primary key is always the final ordering condition
- associations are untested and probably do not work
    - (left) joins are known to work though

## Usage

Fob works primarily by composing Ecto queries with `Ecto.Query.where/3` and
`Ecto.Query.limit/2`. In general, the tracking of page breaks is left to any
consuming library/application, but Fob provides a convenience tool which it
uses internally for easy testing: `Fob.Cursor`.

A `Fob.Cursor` is a similar idea to a standard elixir `Stream` except that it
does not represent an active connection to a resource (some but not all Elixir
`Stream`s open a process or port and therefore represent a connection to
resource. This disallows some functionality which is desirable for Fob, such
as [`Stream.split/2`](https://github.com/elixir-lang/elixir/issues/2922)).

With the cursor, you may walk through the pages of a dataset with
`Fob.Cursor.next/1` and take multiple pages with `Fob.Cursor.split/2`

```elixir
iex> alias Fob.Cursor
iex> import Ecto.Query, only: [order_by: 2]
iex> cursor = Cursor.new(order_by(MySchema, asc: :id), MyApp.Repo, _initial_pagination = nil, _page_size = 3)
#Fob.Cursor<...>
iex> {_records, cursor} = Cursor.next(cursor)
{[%{id: 1}, %{id: 2}, %{id: 3}], #Fob.Cursor<...>}
iex> {_records, cursor} = Cursor.next(cursor)
{[%{id: 4}, %{id: 5}, %{id: 6}], #Fob.Cursor<...>}
iex> {_records, cursor} = Cursor.split(cursor, 2)
{[%{id: 7}, %{id: 8}, %{id: 9}, %{id: 10}, %{id: 11}, %{id: 12}], #Fob.Cursor<...>}
```

## Why?

Why build an incomplete and minimal keyset pagination
library when there are already workable implementations in
[Paginator](https://github.com/duffelhq/paginator) and
[Quarto](https://github.com/maartenvanvliet/quarto)? Fob was originally cut
out of another library called Haste. In our setup, Haste satisfies all of the
above assumptions.

## Installation

```elixir
def deps do
  [
    {:fob, "~> 1.0"}
  ]
end
```

Check out the docs here: https://hexdocs.pm/fob
