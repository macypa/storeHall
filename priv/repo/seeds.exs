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

alias StoreHall.Users.User
alias StoreHall.Repo

id = Application.get_env(:storeHall, :about)[:user_id]

case Repo.get(User, id) do
  # User not found, we build one
  nil -> %User{id: id} |> IO.inspect(label: 'id')
  # User exists, let's use it
  user -> user
end
|> User.changeset(Application.get_env(:storeHall, :about)[:user])
|> Repo.insert_or_update!()
