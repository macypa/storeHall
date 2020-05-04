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
  alias StoreHall.Reactions
  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext

  @scode_names [
    staff: Gettext.gettext("staff"),
    friendly: Gettext.gettext("friendly"),
    clean: Gettext.gettext("clean"),
    price: Gettext.gettext("price"),
    quality: Gettext.gettext("quality")
  ]
  def scode_names, do: @scode_names
  def max_score_points, do: 10
  def max_scores_sum_points, do: length(scode_names()) * max_score_points()

  def validate_scores(rating) do
    case rating["rating_id"] do
      nil ->
        max_score = max_scores_sum_points()

        scores_map = rating["details"]["scores"] |> scores_to_map()

        scores_map
        |> Map.values()
        |> Enum.reduce(0, fn score, acc -> acc + score end)
        |> case do
          x when x > max_score -> false
          _ -> validate_individual_scores(scores_map)
        end

      _ ->
        true
    end
  end

  defp scores_to_map(scores) do
    scores
    |> Enum.reduce(%{}, fn score, acc ->
      key = String.split(score, ":", trim: true) |> hd
      value = score |> String.replace_prefix(key <> ":", "") |> parse_score_value_int()

      Map.put(acc, key, value)
    end)
  end

  defp parse_score_value_int(score_value) when is_binary(score_value) do
    score_value
    |> Integer.parse()
    |> case do
      {int, ""} -> int
      :error -> 0
    end
  end

  defp validate_individual_scores(scores_map) do
    max_score = max_score_points()

    scores_map
    |> Map.values()
    |> Enum.reduce(true, fn score, acc ->
      case score do
        x when x > max_score -> false
        _ -> acc
      end
    end)
  end

  def preload_for(item_user, current_user_id, params) do
    item_user
    |> Map.put(
      :ratings,
      Ecto.assoc(item_user, :ratings)
      |> where([r], is_nil(r.rating_id))
      |> apply_filters(
        current_user_id,
        params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"})
      )
    )
  end

  def rating_template() do
    %{
      id: "{{id}}",
      author_id: "{{author_id}}",
      author: %{
        id: "{{author.id}}",
        image: "{{author.image}}",
        details: %{
          "rating" => %{"score" => "{{author.details.rating.score}}"}
        }
      },
      user_id: "{{user_id}}",
      user: %{
        id: "{{author.id}}",
        image: "{{author.image}}"
      },
      item_id: "{{item_id}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      alertz_count: "{{alertz_count}}",
      lolz_count: "{{lolz_count}}",
      wowz_count: "{{wowz_count}}",
      mehz_count: "{{mehz_count}}",
      reaction: %{
        reaction: "{{reaction.reaction}}"
      },
      details: %{
        "scores" => "{{json details.scores}}",
        "body" => "{{details.body}}"
      }
    }
  end

  def list_ratings(
        module,
        current_user_id,
        params = %{"id" => id, "show_for_rating_id" => rating_id}
      ) do
    module.get!(id)
    |> Ecto.assoc(:ratings)
    |> where_rating_id(params, rating_id)
    |> apply_filters(current_user_id, params)
  end

  def list_ratings(module, current_user_id, params = %{"id" => id}) do
    module.get!(id)
    |> Ecto.assoc(:ratings)
    |> where([r], is_nil(r.rating_id))
    |> apply_filters(
      current_user_id,
      params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"})
    )
  end

  def apply_filters(item_user, current_user_id, params) do
    author_preload_query = from(u in User) |> Users.add_select_fields_for_preload([])

    item_user
    |> preload(author: ^author_preload_query)
    |> Reactions.preload_reaction(current_user_id, "rating")
    |> DefaultFilter.show_with_min_rating(:author, current_user_id)
    |> DefaultFilter.show_with_max_alerts(current_user_id)
    |> DefaultFilter.order_first_for(current_user_id)
    |> DefaultFilter.sort_filter(params)
    |> DefaultFilter.paging_filter(params)
    |> Repo.all()
    |> Users.clean_preloaded_user(:author, [:info, :marketing_info])
  end

  def where_rating_id(query, _params, rating_id) do
    query
    |> where(rating_id: ^parse_rating_id(rating_id))
  end

  def parse_rating_id(id) do
    {id, _} = to_string(id) |> Integer.parse()
    id
  end

  def upsert_item_rating(rating \\ %{}) do
    Multi.new()
    |> insert_or_update_item_rating(rating)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        case Map.has_key?(multi, :calc_item_rating) do
          true ->
            {:ok,
             multi.insert
             |> Users.preload_author(Repo)
             |> Reactions.preload_reaction(Repo, rating["author_id"], "rating"),
             multi.calc_item_rating, multi.calc_user_rating}

          _ ->
            {:ok,
             multi.insert
             |> Users.preload_author(Repo)
             |> Reactions.preload_reaction(Repo, rating["author_id"], "rating")}
        end

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def upsert_user_rating(rating \\ %{}) do
    Multi.new()
    |> insert_or_update_user_rating(rating)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        case Map.has_key?(multi, :calc_user_rating) do
          true ->
            {:ok,
             multi.insert
             |> Users.preload_author(Repo)
             |> Reactions.preload_reaction(Repo, rating["author_id"], "rating"),
             multi.calc_user_rating}

          _ ->
            {:ok,
             multi.insert
             |> Users.preload_author(Repo)
             |> Reactions.preload_reaction(Repo, rating["author_id"], "rating")}
        end

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp insert_or_update_item_rating(multi, rating) do
    case rating["rating_id"] do
      nil ->
        multi
        |> Multi.run(:rating_db, fn repo, _changes ->
          query =
            from r in ItemRating,
              where:
                is_nil(r.rating_id) and
                  r.item_id == ^rating["item_id"] and
                  r.user_id == ^rating["user_id"] and
                  r.author_id == ^rating["author_id"]

          {:ok, repo.one(query)}
        end)
        |> Multi.run(:insert, fn repo, %{rating_db: rating_from_db} ->
          case rating_from_db do
            nil ->
              ItemRating.changeset(%ItemRating{}, rating) |> repo.insert()

            rating_from_db ->
              ItemRating.changeset(rating_from_db, rating) |> repo.update()
          end
        end)
        |> Multi.merge(fn %{rating_db: rating_from_db} ->
          case rating_from_db do
            nil ->
              Multi.new()
              |> update_item_rating(rating["item_id"], rating, true)

            rating_from_db ->
              negated_old_scores =
                rating_from_db.details["scores"]
                |> scores_to_map()
                |> Map.values()
                |> Enum.reduce(0, fn score, acc -> acc + score end)
                |> Kernel.*(-1)

              new_scores =
                rating["details"]["scores"]
                |> scores_to_map()
                |> Map.values()
                |> Enum.reduce(0, fn score, acc -> acc + score end)

              Multi.new()
              |> update_item_rating(rating["item_id"], negated_old_scores + new_scores, false)
          end
        end)

      _ ->
        multi
        |> Multi.insert(:insert, ItemRating.changeset(%ItemRating{}, rating))
    end
  end

  defp insert_or_update_user_rating(multi, rating) do
    case rating["rating_id"] do
      nil ->
        multi
        |> Multi.run(:rating_db, fn repo, _changes ->
          query =
            from r in UserRating,
              where:
                is_nil(r.rating_id) and
                  r.user_id == ^rating["user_id"] and
                  r.author_id == ^rating["author_id"]

          {:ok, repo.one(query)}
        end)
        |> Multi.run(:insert, fn repo, %{rating_db: rating_from_db} ->
          case rating_from_db do
            nil ->
              UserRating.changeset(%UserRating{}, rating) |> repo.insert()

            rating_from_db ->
              UserRating.changeset(rating_from_db, rating) |> repo.update()
          end
        end)
        |> Multi.merge(fn %{rating_db: rating_from_db} ->
          case rating_from_db do
            nil ->
              Multi.new()
              |> update_user_rating(rating["user_id"], rating, true)

            rating_from_db ->
              negated_old_scores =
                rating_from_db.details["scores"]
                |> scores_to_map()
                |> Map.values()
                |> Enum.reduce(0, fn score, acc -> acc + score end)
                |> Kernel.*(-1)

              new_scores =
                rating["details"]["scores"]
                |> scores_to_map()
                |> Map.values()
                |> Enum.reduce(0, fn score, acc -> acc + score end)

              Multi.new()
              |> update_user_rating(rating["user_id"], negated_old_scores + new_scores, false)
          end
        end)

      _ ->
        multi
        |> Multi.insert(:insert, UserRating.changeset(%UserRating{}, rating))
    end
  end

  def update_item_rating(multi, item_id, rating \\ [5], incr_count \\ false)
  def update_item_rating(multi, _item_id, nil, _incr_count), do: multi
  def update_item_rating(multi, _item_id, [nil], _incr_count), do: multi

  def update_item_rating(multi, item_id, rating, incr_count) do
    multi
    |> Multi.run(:item, fn repo, %{} ->
      {:ok, Items.get_item!(item_id, repo)}
    end)
    |> Multi.run(:calc_item_rating, fn repo, %{item: item} ->
      calculate_rating_score(rating, repo, Item, item, incr_count)
    end)
    |> update_user_rating(nil, rating)
  end

  def update_user_rating(multi, user_id, rating \\ [5], incr_count \\ false)
  def update_user_rating(multi, _user_id, [nil], _incr_count), do: multi
  def update_user_rating(multi, _user_id, nil, _incr_count), do: multi

  def update_user_rating(multi, user_id, rating, incr_count) do
    multi
    |> Multi.run(:user, fn repo, changes ->
      case changes do
        %{item: item} -> {:ok, Users.get_user!(item.user_id, [], repo)}
        _ -> {:ok, Users.get_user!(user_id, [], repo)}
      end
    end)
    |> Multi.run(:calc_user_rating, fn repo, %{user: user} ->
      calculate_rating_score(rating, repo, User, user, incr_count)
    end)
  end

  defp calculate_rating_score(rating, repo, query, item_or_user, incr_count)
       when is_map(rating) do
    calculate_rating_score(
      Map.values(rating["details"]["scores"] |> scores_to_map()),
      repo,
      query,
      item_or_user,
      incr_count
    )
  end

  defp calculate_rating_score(rating, repo, query, item_or_user, incr_count) do
    score =
      to_string(
        calc_rating(
          rating,
          item_or_user.details["rating"]["count"],
          item_or_user.details["rating"]["score"]
        )
      )

    # count = length(rating)
    # increase by 1 for every rating disregarding the score count
    count = 1

    query =
      case incr_count do
        true ->
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

        false ->
          from u in query,
            where: u.id == ^item_or_user.id,
            update: [
              set: [
                details:
                  fragment(
                    " jsonb_set(details, '{rating, score}', ?::text::jsonb) ",
                    ^score
                  )
              ]
            ]
      end

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
