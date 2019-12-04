defmodule StoreHall.ReactionFields do
  use Ecto.Schema

  defmacro reaction_fields do
    quote do
      field :lolz_count, :integer, virtual: true
      field :wowz_count, :integer, virtual: true
      field :mehz_count, :integer, virtual: true
      field :alertz_count, :integer, virtual: true

      has_one :reaction, StoreHall.Reaction,
        foreign_key: :reacted_to,
        where: [type: "comment"]
    end
  end
end
