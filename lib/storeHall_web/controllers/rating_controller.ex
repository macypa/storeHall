defmodule StoreHallWeb.RatingController do
  use StoreHallWeb, :controller

  alias StoreHall.Ratings

  def create(conn, %{"item_rating" => rating_params, "item_id" => item_id}) do
    rating_params =
      rating_params
      |> put_in(
        ["details", "scores"],
        Poison.decode!(get_in(rating_params, ["details", "scores"]))
      )

    case Ratings.create_item_rating(rating_params) do
      {:ok, _rating} ->
        conn
        |> put_flash(:info, "ItemRating created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Already rated.")
        |> redirect(to: Routes.item_path(conn, :show, item_id))
    end
  end

  def create(conn, %{"user_rating" => rating_params, "user_id" => user_id}) do
    rating_params =
      rating_params
      |> put_in(
        ["details", "scores"],
        Poison.decode!(get_in(rating_params, ["details", "scores"]))
      )

    case Ratings.create_user_rating(rating_params) do
      {:ok, _rating} ->
        conn
        |> put_flash(:info, "UserRating created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Already rated.")
        |> redirect(to: Routes.user_path(conn, :show, user_id))
    end
  end
end
