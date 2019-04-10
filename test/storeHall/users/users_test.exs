defmodule StoreHall.UsersTest do
  use StoreHall.DataCase

  alias StoreHall.Users

  describe "users" do
    alias StoreHall.Users.User

    @valid_attrs %{
      id: "some_id",
      email: "some email",
      image: "",
      first_name: "some first_name",
      last_name: "some last_name",
      provider: "some provider"
    }
    @update_attrs %{
      id: "some_id",
      email: "some updated email",
      first_name: "some updated first_name",
      last_name: "some updated last_name",
      provider: "some updated provider"
    }
    @invalid_attrs %{id: "some_id", email: nil, first_name: nil, last_name: nil, provider: nil}

    def user_fixture(attrs \\ @valid_attrs) do
      {:ok, user} =
        User.changeset(%User{id: attrs.id}, attrs)
        |> Repo.insert()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Repo.all(User) == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Users.get_user!(user.id) == user
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Users.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.first_name == "some updated first_name"
      assert user.last_name == "some updated last_name"
      assert user.provider == "some updated provider"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
      assert user == Users.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
