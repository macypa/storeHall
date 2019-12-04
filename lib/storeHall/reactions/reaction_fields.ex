defmodule StoreHall.ReactionFields do
  use Ecto.Schema

  @jason_fields [:reaction, :lolz_count, :wowz_count, :mehz_count, :alertz_count]
  def reaction_jason_fields(), do: @jason_fields

  defmacro reaction_fields(type) do
    quote do
      field :lolz_count, :integer, virtual: true
      field :wowz_count, :integer, virtual: true
      field :mehz_count, :integer, virtual: true
      field :alertz_count, :integer, virtual: true

      has_one :reaction, StoreHall.Reaction,
        foreign_key: :reacted_to,
        where: [type: unquote(type)]
    end
  end
end
