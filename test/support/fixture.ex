defmodule StoreHall.Fixture do
  use ExUnitProperties

  alias StoreHall.Repo
  alias StoreHall.Items
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Comments.ItemComment
  alias StoreHall.Comments.UserComment
  import Ecto.Query, warn: false

  @users_count 100
  @items_count 100
  @item_comments_count 100

  @dialyzer {:no_return, ueberauth_generator: 0}
  def ueberauth_generator() do
    ExUnitProperties.gen all(
                           token <- StreamData.string(:alphanumeric),
                           name <- StreamData.string(:alphanumeric),
                           email <- StreamData.string(:alphanumeric)
                         ) do
      %{
        credentials: %{token: token},
        info: %{
          email: "#{email}@gmail.com",
          name: "test_#{name}",
          image: ""
        },
        provider: :google
      }
    end
  end

  @dialyzer {:no_return, generate_ueberauth: 0}
  def generate_ueberauth() do
    ExUnitProperties.pick(ueberauth_generator())
  end

  @dialyzer {:no_return, user_generator: 0}
  @dialyzer {:no_return, user_generator: 1}
  def user_generator(fun \\ &Repo.insert/1) do
    ExUnitProperties.gen all(
                           seed <- StreamData.string(:alphanumeric),
                           seed not in Enum.map(Repo.all(User), fn u -> u.id end),
                           seed != ""
                         ) do
      {:ok, user} =
        fun.(
          User.changeset(%User{id: seed}, %{
            email: seed,
            image: "",
            name: seed,
            provider: seed
          })
        )

      user
      |> Users.update_user(%{
        marketing_info: user.marketing_info |> Map.put("marketing_consent", "agreed")
      })
      |> elem(1)
      |> Map.drop([:settings])

      # |> Repo.insert()
    end
  end

  @dialyzer {:no_return, insert_users: 0}
  @dialyzer {:no_return, insert_users: 1}
  def insert_users(count \\ @users_count) do
    Enum.take(user_generator(), count)
  end

  @dialyzer {:no_return, generate_user: 0}
  def generate_user() do
    ExUnitProperties.pick(user_generator())
  end

  @dialyzer {:no_return, delete_users: 0}
  def delete_users() do
    Repo.all(User)
    |> Enum.each(fn u ->
      StoreHall.Users.delete_user(u)
    end)
  end

  def item_generator_fun_do_none(item_attrs, _name) do
    item_attrs
  end

  @dialyzer {:no_return, item_generator: 0}
  @dialyzer {:no_return, item_generator: 1}
  @dialyzer {:no_return, item_generator: 2}
  def item_generator(user \\ nil, fun \\ &create_item/2) do
    user =
      case user do
        nil -> generate_user()
        user -> user
      end

    ExUnitProperties.gen all(
                           name <- StreamData.string(:alphanumeric),
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
                           images <-
                             StreamData.uniq_list_of(
                               StreamData.string(:alphanumeric, max_length: 5),
                               max_length: 5
                             ),
                           count <- StreamData.positive_integer(),
                           score <- StreamData.integer(-1..500),
                           comments_count <- StreamData.positive_integer()
                         ) do
      %{
        "details" => %{
          "tags" => tags |> Enum.reject(&is_nil/1) |> Enum.reject(fn x -> x == "" end),
          "images" => images |> Enum.reject(&is_nil/1) |> Enum.reject(fn x -> x == "" end),
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

  @dialyzer {:no_return, insert_items: 0}
  @dialyzer {:no_return, insert_items: 1}
  def insert_items(count \\ @items_count) do
    Enum.take(item_generator(), count)
  end

  @dialyzer {:no_return, generate_item: 0}
  @dialyzer {:no_return, generate_item: 1}
  def generate_item(user \\ nil) do
    ExUnitProperties.pick(item_generator(user))
  end

  @dialyzer {:no_return, item_comment_generator: 1}
  @dialyzer {:no_return, item_comment_generator: 2}
  @dialyzer {:no_return, item_comment_generator: 3}
  @dialyzer {:no_return, item_comment_generator: 4}
  @dialyzer {:no_return, item_comment_generator: 5}
  def item_comment_generator(
        author,
        item \\ nil,
        user \\ nil,
        comment_id \\ nil,
        fun \\ &Repo.insert/1
      ) do
    item =
      case item do
        nil -> generate_item(user)
        item -> item
      end

    ExUnitProperties.gen all(body <- StreamData.string(:alphanumeric)) do
      {:ok, item_comment} =
        fun.(
          ItemComment.changeset(%ItemComment{}, %{
            comment_id: comment_id,
            item_id: item.id,
            user_id: item.user_id,
            author_id: author.id,
            author: author,
            details: %{"body" => body}
          })
        )

      item_comment

      # |> Repo.insert()
    end
  end

  @dialyzer {:no_return, insert_item_comments: 1}
  @dialyzer {:no_return, insert_item_comments: 2}
  @dialyzer {:no_return, insert_item_comments: 3}
  @dialyzer {:no_return, insert_item_comments: 4}
  @dialyzer {:no_return, insert_item_comments: 5}
  def insert_item_comments(
        author,
        item \\ nil,
        user \\ nil,
        comment_id \\ nil,
        count \\ @item_comments_count
      ) do
    Enum.take(item_comment_generator(author, item, user, comment_id), count)
  end

  @dialyzer {:no_return, generate_item_comment: 1}
  @dialyzer {:no_return, generate_item_comment: 2}
  @dialyzer {:no_return, generate_item_comment: 3}
  @dialyzer {:no_return, generate_item_comment: 4}
  def generate_item_comment(author, item \\ nil, user \\ nil, comment_id \\ nil) do
    ExUnitProperties.pick(item_comment_generator(author, item, user, comment_id))
  end

  @dialyzer {:no_return, user_comment_generator: 1}
  @dialyzer {:no_return, user_comment_generator: 2}
  @dialyzer {:no_return, user_comment_generator: 3}
  @dialyzer {:no_return, user_comment_generator: 4}
  def user_comment_generator(author, user \\ nil, comment_id \\ nil, fun \\ &Repo.insert/1) do
    user =
      case user do
        nil -> generate_user()
        user -> user
      end

    ExUnitProperties.gen all(body <- StreamData.string(:alphanumeric)) do
      {:ok, user_comment} =
        fun.(
          UserComment.changeset(%UserComment{}, %{
            comment_id: comment_id,
            user_id: user.id,
            author_id: author.id,
            author: author,
            details: %{"body" => body}
          })
        )

      user_comment

      # |> Repo.insert()
    end
  end

  @dialyzer {:no_return, insert_user_comments: 1}
  @dialyzer {:no_return, insert_user_comments: 2}
  @dialyzer {:no_return, insert_user_comments: 3}
  @dialyzer {:no_return, insert_user_comments: 4}
  def insert_user_comments(author, user \\ nil, comment_id \\ nil, count \\ @item_comments_count) do
    Enum.take(user_comment_generator(author, user, comment_id), count)
  end

  @dialyzer {:no_return, generate_user_comment: 1}
  @dialyzer {:no_return, generate_user_comment: 2}
  @dialyzer {:no_return, generate_user_comment: 3}
  def generate_user_comment(author, user \\ nil, comment_id \\ nil) do
    ExUnitProperties.pick(user_comment_generator(author, user, comment_id))
  end

  def unused_generate() do
    StreamData.unshrinkable(StreamData.string(:alphanumeric))
  end
end
