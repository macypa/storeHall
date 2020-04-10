defmodule StoreHall.Users.Action do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias StoreHall.Repo

  alias StoreHall.Items
  alias StoreHall.Users.Relation
  alias StoreHall.Ratings
  alias StoreHall.Reaction
  alias StoreHall.Users.Label
  alias StoreHall.Users.Settings

  @default_reaction "meh"
  def default_reaction(), do: @default_reaction

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
        author_id,
        type,
        reaction,
        fun_on_update \\ &update_user_rating_fun/3
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
          fun_on_update.(repo, author_id, [reaction_to_rating(reaction)])

        reaction_db ->
          # no updating to @default_reaction
          if reaction != default_reaction() do
            if reaction_db.reaction == reaction do
              # fun_on_update.(repo, author_id, [-reaction_to_rating(reaction_db.reaction)])  # this will negate the rating
              # default reaction @default_reaction ...acting as seen and will not be visible to user
              with {:ok, _split_field} <-
                     fun_on_update.(repo, author_id, [
                       -reaction_to_rating(reaction_db.reaction)
                     ]) do
                fun_on_update.(repo, author_id, [reaction_to_rating(default_reaction())])
              end
            else
              with {:ok, _split_field} <-
                     fun_on_update.(repo, author_id, [
                       -reaction_to_rating(reaction_db.reaction)
                     ]) do
                fun_on_update.(repo, author_id, [reaction_to_rating(reaction)])
              end
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
          # no updating to @default_reaction
          if reaction != default_reaction() do
            if reaction_db.reaction == reaction do
              # reaction_db |> repo.delete()   # this will toggle the reaction
              # default reaction @default_reaction ...acting as seen and will not be visible to user
              reaction_db
              |> Reaction.changeset(Map.put(%{}, :reaction, default_reaction()))
              |> repo.update()
            else
              reaction_db
              |> Reaction.changeset(Map.put(%{}, :reaction, reaction))
              |> repo.update()
            end
          end
      end
    end)
  end

  def init_item_reaction(
        reacted_to,
        current_user_id,
        author_id,
        reaction \\ @default_reaction
      ) do
    Multi.new()
    |> Multi.run(:update_rating_for_reaction, fn repo, _ ->
      update_user_rating_fun(repo, author_id, [reaction_to_rating(reaction)])
    end)
    |> Multi.run(:init_reaction, fn repo, _ ->
      Reaction.changeset(%Reaction{}, %{
        user_id: current_user_id,
        reacted_to: reacted_to,
        type: "item",
        reaction: reaction
      })
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  def update_user_rating_fun(repo, author_id, reaction) do
    case author_id do
      item_id when is_integer(item_id) ->
        Multi.new()
        |> Ratings.update_item_rating(item_id, reaction)
        |> repo.transaction()

      user_id when is_binary(user_id) ->
        Multi.new()
        |> Ratings.update_user_rating(user_id, reaction)
        |> repo.transaction()
    end
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

  def reaction_to_rating("alert" <> _), do: -10
  def reaction_to_rating(reaction) when reaction in [@default_reaction], do: 1
  def reaction_to_rating(reaction) when reaction in ["wow"], do: 3
  def reaction_to_rating(reaction) when reaction in ["lol"], do: -3
  def reaction_to_rating(_reaction), do: 0
end
