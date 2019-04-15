defmodule StoreHall.UsersTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Users
  alias StoreHall.Users.User

  @users_count 100
  @update_attrs %{
    id: "some_id",
    email: "some updated email",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    provider: "some updated provider"
  }
  @invalid_attrs %{id: "some_id", email: nil, first_name: nil, last_name: nil, provider: nil}

  test "list_users/0 returns all users" do
    users = Fixture.insert_users(@users_count)
    assert length(Repo.all(User)) == length(users)
  end

  test "get_user!/1 returns the user with given id" do
    users = Fixture.insert_users(@users_count)

    check all user <- StreamData.member_of(users) do
      assert Users.get_user!(user.id) == user
    end
  end

  describe "update" do
    test "update_user/2 with valid data updates the user" do
      check all user <- StoreHall.Fixture.user_generator() do
        assert {:ok, %User{} = user} = Users.update_user(user, @update_attrs)
        assert user.email == "some updated email"
        assert user.first_name == "some updated first_name"
        assert user.last_name == "some updated last_name"
        assert user.provider == "some updated provider"
      end
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = StoreHall.Fixture.generate_user()
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
      assert user == Users.get_user!(user.id)
    end
  end

  test "delete_user/1 deletes the user" do
    check all user <- StoreHall.Fixture.user_generator() do
      assert {:ok} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end
  end

  test "change_user/1 returns a user changeset" do
    users = Fixture.insert_users(@users_count)

    check all user <- StreamData.member_of(users) do
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
