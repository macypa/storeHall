defmodule StoreHall.Reactions do
  import Ecto.Query, warn: false
  alias StoreHall.Reaction

  def preload_reactions_counts(query) do
    query
    |> join(:left, [c], rl in Reaction,
      on: rl.reacted_to == c.id and rl.reaction == "lol" and rl.type == "comment",
      as: :rl
    )
    |> join(:left, [c], rw in Reaction,
      on: rw.reacted_to == c.id and rw.reaction == "wow" and rw.type == "comment",
      as: :rw
    )
    |> join(:left, [c], rm in Reaction,
      on: rm.reacted_to == c.id and rm.reaction == "meh" and rm.type == "comment",
      as: :rm
    )
    |> join(:left, [c], ra in Reaction,
      on: ra.reacted_to == c.id and ra.reaction == "alert" and ra.type == "comment",
      as: :ra
    )
    |> group_by([c], c.id)
    |> select_merge([c, rl: r], %{lolz_count: count(r.id)})
    |> select_merge([c, rw: r], %{wowz_count: count(r.id)})
    |> select_merge([c, rm: r], %{mehz_count: count(r.id)})
    |> select_merge([c, ra: r], %{alertz_count: count(r.id)})
  end

  def preload_reaction(query, current_user_id) do
    reactions_query =
      Reaction |> where([r], r.user_id == ^to_string(current_user_id) and r.type == "comment")

    query
    |> preload(reaction: ^reactions_query)
    |> preload_reactions_counts()
  end
end
