defmodule StoreHall.Ratings do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo

  alias StoreHall.Ratings.ItemRating
  alias StoreHall.Ratings.UserRating

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

  def create_item_rating(attrs \\ %{}) do
    %ItemRating{}
    |> ItemRating.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_rating(attrs \\ %{}) do
    %UserRating{}
    |> UserRating.changeset(attrs)
    |> Repo.insert()
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
  def calc_rating(value, 0, rating, _c), do: calc_rating(value, 1, rating)

  def calc_rating(data, _count, rating, c) when is_list(data) do
    data
    |> Enum.reduce(%{count: 0, rating: rating}, fn value, acc ->
      %{count: acc.count + 1, rating: calc_rating(value, acc.count, acc.rating, c)}
    end)
    |> Map.get(:rating)
  end

  def calc_rating(value, count, rating, c) do
    multiplier = c / (count + 2)
    Float.round((value - rating) * multiplier + rating, 2)
  end
end
