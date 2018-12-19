defmodule StoreHall.Users.Action do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Ratings
  alias StoreHall.Users.Relations
  alias StoreHall.Users.Settings

  def add_relation(multi, user_id, current_user_id, reaction \\ 5)

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

  def inc_label_count(label, user_id) do
    query =
      from f in Settings,
        where: f.id == ^user_id,
        update: [
          set: [
            settings:
              fragment(
                " jsonb_set(settings, '{labels, ?}',
                 (COALESCE(settings->'labels'->>'?','0')::int + 1)::text::jsonb) ",
                ^label,
                ^label
              )
          ]
        ]

    Repo.update_all(query, [])
  end
end
