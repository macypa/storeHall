defmodule StoreHall.Fixture do
  use ExUnitProperties

  alias StoreHall.Repo
  alias StoreHall.Items
  alias StoreHall.Users.User
  import Ecto.Query, warn: false

  @users_count 100
  @items_count 100

  def ueberauth_generator() do
    ExUnitProperties.gen all token <- StreamData.string(:alphanumeric),
                             first_name <- StreamData.string(:alphanumeric),
                             last_name <- StreamData.string(:alphanumeric),
                             email <- StreamData.string(:alphanumeric) do
      %{
        credentials: %{token: token},
        info: %{
          email: "#{email}@gmail.com",
          first_name: "test_#{first_name}",
          last_name: last_name,
          image: ""
        },
        provider: :google
      }
    end
  end

  def generate_ueberauth() do
    ExUnitProperties.pick(ueberauth_generator())
  end

  def user_generator(fun \\ &Repo.insert/1) do
    ExUnitProperties.gen all seed <- StreamData.string(:alphanumeric),
                             seed not in Enum.map(Repo.all(User), fn u -> u.id end),
                             seed != "" do
      {:ok, user} =
        fun.(
          User.changeset(%User{id: seed}, %{
            email: seed,
            image: "",
            first_name: seed,
            last_name: seed,
            provider: seed
          })
        )

      user

      # |> Repo.insert()
    end
  end

  def insert_users(count \\ @users_count) do
    Enum.take(user_generator(), count)
  end

  def generate_user() do
    ExUnitProperties.pick(user_generator())
  end

  def delete_users() do
    Repo.all(User)
    |> Enum.each(fn u ->
      StoreHall.Users.delete_user(u)
    end)
  end

  def item_generator_fun_do_none(item_attrs, _name) do
    item_attrs
  end

  def item_generator(user \\ nil, fun \\ &create_item/2) do
    user =
      case user do
        nil -> generate_user()
        user -> user
      end

    ExUnitProperties.gen all name <- StreamData.string(:alphanumeric),
                             # name not in Enum.map(
                             #   Repo.all(Item |> where(user_id: ^user.id)),
                             #   fn item -> item.name end
                             # ),
                             name != "",
                             tags <-
                               StreamData.uniq_list_of(
                                 StreamData.string(:alphanumeric, max_length: 5),
                                 max_length: 5
                               ),
                             count <- StreamData.positive_integer(),
                             score <- StreamData.integer(0..5),
                             comments_count <- StreamData.positive_integer() do
      %{
        "details" => %{
          "tags" => tags |> Enum.reject(&is_nil/1) |> Enum.reject(fn x -> x == "" end),
          "images" => [],
          "rating" => %{"count" => count, "score" => score},
          "comments_count" => comments_count
        },
        "name" => name,
        "user_id" => user.id
      }
      |> fun.(name)
    end
  end

  defp create_item(attrs, name) do
    attrs
    |> Map.put("name", name)
    |> Items.create_item()
    |> case do
      {:ok, item} ->
        item

      {:error, _changeset} ->
        create_item(attrs, name <> "1")
    end
  end

  def insert_items(count \\ @items_count) do
    Enum.take(item_generator(), count)
  end

  def generate_item(user \\ nil) do
    ExUnitProperties.pick(item_generator(user))
  end

  def unused_generate() do
    StreamData.unshrinkable(StreamData.string(:alphanumeric))
  end
end
