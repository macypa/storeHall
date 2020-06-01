defmodule StoreHall.Reactions do
  import Ecto.Query, warn: false
  alias StoreHall.Reaction
  alias StoreHall.Repo

  def preload_reactions_counts(query, type) do
    query
    |> join(:left, [c], rl in Reaction,
      on: rl.reacted_to == c.id and rl.reaction == "lol" and rl.type == ^type,
      as: :rl
    )
    |> join(:left, [c], rw in Reaction,
      on: rw.reacted_to == c.id and rw.reaction == "wow" and rw.type == ^type,
      as: :rw
    )
    |> join(:left, [c], ra in Reaction,
      on: ra.reacted_to == c.id and ilike(ra.reaction, "alert%") and ra.type == ^type,
      as: :ra
    )
    |> join(:left, [c], rm in Reaction,
      on: rm.reacted_to == c.id and rm.type == ^type,
      as: :rm
    )
    |> group_by([c], c.id)
    |> select_merge([c, rl: r], %{lolz_count: count(r.id)})
    |> select_merge([c, rw: r], %{wowz_count: count(r.id)})
    |> select_merge([c, rm: r], %{mehz_count: count(r.id)})
    |> select_merge([c, ra: r], %{alertz_count: count(r.id)})
  end

  def preload_reaction(query, nil, _type), do: query

  def preload_reaction(query, current_user_id, type) do
    reactions_query =
      Reaction
      |> where([r], r.user_id == ^to_string(current_user_id) and r.type == ^type)

    query
    |> preload(reaction: ^reactions_query)
    |> preload_reactions_counts(type)
  end

  def preload_reaction(model, repo, current_user_id, type) do
    # Reaction |> where([r], r.user_id == ^to_string(current_user_id) and r.type == ^type)
    # reactions_query =

    model
    |> repo.preload(
      reaction:
        from(
          r in Reaction,
          where: r.user_id == ^to_string(current_user_id) and r.type == ^type
        )
    )

    # |> preload_reactions_counts(type)
  end

  def list_alert_reactions(type \\ "item", days_back \\ 2, repo \\ Repo) do
    Reaction
    |> where(
      [r],
      ilike(r.reaction, "alert%") and r.type == ^type and
        r.inserted_at > date_add(^DateTime.utc_now(), ^(-days_back), "day")
    )
    |> order_by(desc: :reacted_to)
    |> repo.all()
  end
end
