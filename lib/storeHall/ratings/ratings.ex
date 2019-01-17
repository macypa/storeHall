defmodule StoreHall.Ratings do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Ratings.ItemRating
  alias StoreHall.Ratings.UserRating
  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Users
  alias StoreHall.Users.User

  def list_item_ratings do
    Repo.all(ItemRating)
  end

  def list_user_ratings do
    Repo.all(UserRating)
  end

  def get_item_rating!(id), do: Repo.get!(ItemRating, id)

  def for_item(id) do
    ItemRating
    |> where(item_id: ^id)
    |> Repo.all()
  end

  def for_user(id) do
    UserRating
    |> where(user_id: ^id)
    |> Repo.all()
  end

  def create_item_rating(rating \\ %{}) do
    Multi.new()
    |> update_item_rating(rating["item_id"])
    |> Multi.insert(:insert, ItemRating.changeset(%ItemRating{}, rating))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert, multi.calc_item_rating, multi.calc_user_rating}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def create_user_rating(rating \\ %{}) do
    Multi.new()
    |> update_user_rating(rating["user_id"], rating)
    |> Multi.insert(:insert, UserRating.changeset(%UserRating{}, rating))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert, multi.calc_user_rating}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def update_item_rating(multi, item_id, rating \\ [5])
  def update_item_rating(multi, _item_id, nil), do: multi

  def update_item_rating(multi, item_id, rating) do
    multi
    |> Multi.run(:item, fn repo, %{} ->
      {:ok, Items.get_item!(item_id, repo)}
    end)
    |> Multi.run(:calc_item_rating, fn repo, %{item: item} ->
      calculate_rating_score(rating, repo, Item, item)
    end)
    |> update_user_rating(nil, rating)
  end

  def update_user_rating(multi, user_id, rating \\ [5])
  def update_user_rating(multi, _user_id, nil), do: multi

  def update_user_rating(multi, user_id, rating) do
    multi
    |> Multi.run(:user, fn repo, changes ->
      case changes do
        %{item: item} -> {:ok, Users.get_user!(item.user_id, repo)}
        _ -> {:ok, Users.get_user!(user_id, repo)}
      end
    end)
    |> Multi.run(:calc_user_rating, fn repo, %{user: user} ->
      calculate_rating_score(rating, repo, User, user)
    end)
  end

  def calculate_rating_score(rating, repo, query, item_or_user) when is_map(rating) do
    calculate_rating_score(Map.values(rating["details"]["scores"]), repo, query, item_or_user)
  end

  def calculate_rating_score(rating, repo, query, item_or_user) do
    score =
      to_string(
        calc_rating(
          rating,
          item_or_user.details["rating"]["count"],
          item_or_user.details["rating"]["score"]
        )
      )

    count = length(rating)

    query =
      from u in query,
        where: u.id == ^item_or_user.id,
        update: [
          set: [
            details:
              fragment(
                " jsonb_set(
                    jsonb_set(details, '{rating, score}', ?::text::jsonb),
                    '{rating, count}', (COALESCE(details->'rating'->>'count','0')::int + ?)::text::jsonb) ",
                ^score,
                ^count
              )
          ]
        ]

    repo.update_all(query, [])
    {:ok, score}
  end

  def construct_item_rating(attrs \\ %{}) do
    %ItemRating{}
    |> ItemRating.changeset(attrs)
  end

  def construct_user_rating(attrs \\ %{}) do
    %UserRating{}
    |> UserRating.changeset(attrs)
  end

  def calc_rating(value, count \\ 0, rating \\ 4, c \\ 2)

  def calc_rating(data, count, rating, c) when is_list(data) do
    data
    |> Enum.reduce(%{count: count, rating: rating}, fn value, acc ->
      %{count: acc.count + 1, rating: calc_rating(value, acc.count, acc.rating, c)}
    end)
    |> Map.get(:rating)
  end

  def calc_rating(value, count, rating, c) do
    multiplier = c / (count + 2)
    Float.round((value - rating) * multiplier + rating, 2)
  end
end
