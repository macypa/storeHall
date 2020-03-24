# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     StoreHall.Repo.insert!(%StoreHall.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias StoreHall.Items.Item
alias StoreHall.Repo
alias StoreHall.Fixer

defmodule StoreHall.Fixer do
  def update(item, new_features) do
    item
    |> Item.changeset(%{
      details:
        item.details
        |> put_in(["features"], new_features)
    })
    |> Repo.update!()
  end

  def update_map(map) when map == %{} do
    nil
  end

  def update_map(item, map) do
    update(
      item,
      map
      |> Enum.reduce([], fn {k, v}, acc ->
        acc ++ ["#{k}:#{v}"]
      end)
    )
  end
end

Item
|> Repo.all()
|> Enum.each(fn item ->
  item.details["features"]
  |> case do
    map when is_map(map) ->
      Fixer.update_map(item, map)

    list when is_list(list) ->
      Fixer.update(
        item,
        list
        |> Enum.reduce([], fn f, acc ->
          entry =
            case f do
              map when is_map(map) ->
                map
                |> Enum.reduce(nil, fn {k, v}, _acc ->
                  "#{k}:#{v}"
                end)

              string when is_binary(string) ->
                string
            end

          acc ++ [entry]
        end)
      )
  end
end)
