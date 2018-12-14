defmodule StoreHall.Users.Action do
  @moduledoc """
  The Ratings context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo

  alias StoreHall.Users.Settings

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
