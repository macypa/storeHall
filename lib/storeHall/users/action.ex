defmodule StoreHall.Users.Action do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias StoreHall.Items
  alias StoreHall.Users.Relation
  alias StoreHall.Reaction
  alias StoreHall.Users.Label
  alias StoreHall.Users.Settings

  def add_relation(multi, user_id, current_user_id, reaction) do
    multi
    |> Multi.insert(
      :insert_relation,
      Relation.changeset(%Relation{}, %{
        user_id: user_id,
        related_to_user_id: current_user_id,
        type: reaction
      })
    )
  end

  def toggle_or_change_reaction(
        multi,
        reacted_to,
        current_user_id,
        type,
        reaction,
        fun_on_update,
        user_item_id
      ) do
    multi
    |> Multi.run(:reaction, fn repo, _changes ->
      {:ok,
       Reaction
       |> where([r], r.reacted_to == ^reacted_to)
       |> where([r], r.user_id == ^current_user_id)
       |> where([r], r.type == ^type)
       |> repo.one}
    end)
    |> Multi.run(:update_rating_for_reaction, fn repo, %{reaction: reaction_db} ->
      case reaction_db do
        nil ->
          fun_on_update.(repo, user_item_id, [reaction_to_rating(reaction)])

        reaction_db ->
          if reaction_db.reaction == reaction do
            fun_on_update.(repo, user_item_id, [-reaction_to_rating(reaction_db.reaction)])
          else
            with {:ok, _split_field} <-
                   fun_on_update.(repo, user_item_id, [
                     -reaction_to_rating(reaction_db.reaction)
                   ]) do
              fun_on_update.(repo, user_item_id, [reaction_to_rating(reaction)])
            end
          end
      end
    end)
    |> Multi.run(:toggle_or_change_reaction, fn repo, %{reaction: reaction_db} ->
      case reaction_db do
        nil ->
          Reaction.changeset(%Reaction{}, %{
            user_id: current_user_id,
            reacted_to: reacted_to,
            type: type,
            reaction: reaction
          })
          |> repo.insert()

        reaction_db ->
          if reaction_db.reaction == reaction do
            reaction_db |> repo.delete()
          else
            reaction_db
            |> Reaction.changeset(Map.put(%{}, :reaction, reaction))
            |> repo.update()
          end
      end
    end)
  end

  def add_label(multi, item_id, user_id, label) do
    multi
    |> Multi.insert(
      :insert_label,
      Label.changeset(%Label{}, %{
        user_id: user_id,
        item_id: Items.get_item_id(item_id),
        label: label
      })
    )
    |> Multi.run(:label_count, fn repo, _ ->
      inc_label_count_in_user_settings(label, repo, user_id)
    end)
  end

  defp inc_label_count_in_user_settings(label, repo, user_id) do
    query =
      from f in Settings,
        where: f.id == ^user_id,
        update: [
          set: [
            settings:
              fragment(
                " jsonb_set(settings, ?,
                 (COALESCE(settings->'labels'->>?,'0')::decimal + 1)::text::jsonb) ",
                ["labels", ^label],
                ^label
              )
          ]
        ]

    {:ok, repo.update_all(query, [])}
  end

  def reaction_to_rating(reaction) when reaction in ["alert"], do: -10
  def reaction_to_rating(reaction) when reaction in ["meh"], do: 1
  def reaction_to_rating(reaction) when reaction in ["wow"], do: 3
  def reaction_to_rating(reaction) when reaction in ["lol"], do: -3
  def reaction_to_rating(_reaction), do: 0
end
