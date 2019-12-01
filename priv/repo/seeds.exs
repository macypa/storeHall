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

User.changeset(
  %User{id: Application.get_env(:storeHall, :about)[:user_id]},
  Application.get_env(:storeHall, :about)[:user]
)
|> Repo.insert!()
