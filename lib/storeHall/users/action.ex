defmodule StoreHall.Users.Action do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias StoreHall.Items
  alias StoreHall.Users.Relations
  alias StoreHall.Users.Labels
  alias StoreHall.Users.Settings

  def add_relation(multi, user_id, current_user_id, reaction) do
    multi
    |> Multi.insert(
      :insert,
      Relations.changeset(%Relations{}, %{
        user_id: user_id,
        related_to_user_id: current_user_id,
        type: reaction
      })
    )
  end

  def add_label(multi, item_id, user_id, label) do
    multi
    |> Multi.insert(
      :insert,
      Labels.changeset(%Labels{}, %{
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

  def reaction_to_rating(reaction) when reaction in ["wow"], do: 3
  def reaction_to_rating(reaction) when reaction in ["lol"], do: -3
  def reaction_to_rating(_reaction), do: nil
end
