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
  alias StoreHall.DefaultFilter

  def preload_for(item_user, current_user_id, params) do
    item_user
    |> Map.put(
      :ratings,
      Ecto.assoc(item_user, :ratings)
      |> apply_filters(current_user_id, params)
      |> Repo.all()
    )
  end

  def list_ratings(module, current_user_id, params = %{"id" => id}) do
    module.get!(id)
    |> Ecto.assoc(:ratings)
    |> apply_filters(current_user_id, params)
    |> Repo.all()
  end

  def apply_filters(item_user, current_user_id, params) do
    item_user
    |> join(:left, [c], u in assoc(c, :author))
    |> preload([:author])
    |> DefaultFilter.paging_filter(params)
    |> DefaultFilter.sort_filter(params)
    |> DefaultFilter.min_author_rating_filter(current_user_id)
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
  def update_item_rating(multi, _item_id, [nil]), do: multi

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
  def update_user_rating(multi, _user_id, [nil]), do: multi
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

  defp calculate_rating_score(rating, repo, query, item_or_user) when is_map(rating) do
    calculate_rating_score(Map.values(rating["details"]["scores"]), repo, query, item_or_user)
  end

  defp calculate_rating_score(rating, repo, query, item_or_user) do
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
                    '{rating, count}', (COALESCE(details->'rating'->>'count','0')::decimal + ?)::text::jsonb) ",
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

  def calc_rating(value, count \\ 0, rating \\ 400, c \\ 2)

  def calc_rating(data, count, rating, c) when is_list(data) do
    data
    |> Enum.reduce(%{count: count, rating: rating}, fn value, acc ->
      %{count: acc.count + 1, rating: calc_rating(value, acc.count, acc.rating, c)}
    end)
    |> Map.get(:rating)
  end

  def calc_rating(value, count, rating, c) when is_binary(value) do
    {value, _} = value |> Integer.parse()
    calc_rating(value, count, rating, c)
  end

  def calc_rating(value, _count, rating, _c) when is_integer(value) do
    value + rating
    # multiplier =
    #  case rating do
    #    -1 -> c / (count + 2)
    #    _rating -> c / (count + 3)
    #  end

    # Decimal.round((value - rating) * multiplier + rating, 2)
  end
end
