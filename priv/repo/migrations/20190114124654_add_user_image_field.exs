defmodule StoreHall.Repo.Migrations.AddUserImageField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :image, :string
    end
  end
end
