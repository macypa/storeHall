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
    # %ItemRating{}
    # |> ItemRating.changeset(attrs)
    # |> Repo.insert()
    Multi.new()
    |> Multi.run(:item, fn repo, %{} ->
      {:ok, Items.get_item!(rating["item_id"], repo)}
    end)
    |> Multi.run(:calc_rating, fn repo, %{item: item} ->
      score =
        to_string(
          calc_rating(
            Map.values(rating["details"]["scores"]),
            item.details["rating"]["count"],
            item.details["rating"]["score"]
          )
        )

      count = Map.size(rating["details"]["scores"])

      query =
        from i in Item,
          where: i.id == ^item.id,
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

      {:ok, repo.update_all(query, [])}
    end)
    |> Multi.insert(:insert, ItemRating.changeset(%ItemRating{}, rating))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def create_user_rating(rating \\ %{}) do
    Multi.new()
    |> Multi.run(:user, fn repo, %{} ->
      {:ok, Users.get_user!(rating["user_id"], repo)}
    end)
    |> Multi.run(:calc_rating, fn repo, %{user: user} ->
      score =
        to_string(
          calc_rating(
            Map.values(rating["details"]["scores"]),
            user.details["rating"]["count"],
            user.details["rating"]["score"]
          )
        )

      count = Map.size(rating["details"]["scores"])

      query =
        from u in User,
          where: u.id == ^user.id,
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

      {:ok, repo.update_all(query, [])}
    end)
    |> Multi.insert(:insert, UserRating.changeset(%UserRating{}, rating))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def update_rating_score() do
    # query =
    #   from f in Settings,
    #     where: f.id == ^id,
    #     update: [
    #       set: [
    #         settings:
    #           fragment(
    #             " jsonb_set(settings, '{labels, liked}', (COALESCE(settings->'labels'->>'liked','0')::int + 1)::text::jsonb) "
    #           )
    #       ]
    #     ]
    #
    # Repo.update_all(query, [])
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
