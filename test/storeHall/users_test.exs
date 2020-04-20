defmodule StoreHall.UsersTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Users.Settings

  @users_count 100
  @update_attrs %{
    id: "some_id",
    email: "some updated email",
    name: "some updated name",
    provider: "some updated provider"
  }
  @invalid_attrs %{id: "", email: nil, name: nil, provider: nil}

  test "list_users/0 returns all users" do
    users = Fixture.insert_users(@users_count)
    assert length(Users.list_users(%{"page-size" => @users_count + 1})) == length(users)
  end

  describe "get" do
    test "get_user!/1 returns the user with given id" do
      check all(user <- Fixture.user_generator()) do
        assert Users.get_user!(user.id) |> Map.drop([:marketing_info]) ==
                 user |> Map.drop([:marketing_info])
      end
    end

    test "get_user!/1 merges default details" do
      user = Fixture.generate_user()

      Users.update_user(user, %{
        "details" => %{"rating" => %{"score" => -1}, "comments_count" => 1}
      })

      assert Users.get_user!(user.id).details["rating"] == %{"count" => 0, "score" => -1}
      assert Users.get_user!(user.id).details["comments_count"] == 1
    end

    test "get_user_with_settings!/1 returns the user with loaded settings" do
      check all(user <- Fixture.user_generator()) do
        Users.update_user(user, %{"settings" => %{"custom_setting" => 0}})

        assert Users.get_user_with_settings!(user.id).settings["custom_setting"] == 0
      end
    end

    test "load_settings/1 returns the user with loaded settings" do
      check all(user <- Fixture.user_generator()) do
        Users.update_user(user, %{"settings" => %{"custom_setting" => 0}})

        assert Users.load_settings(user).settings["custom_setting"] == 0
      end
    end
  end

  describe "update" do
    test "update_user/2 with valid data updates the user" do
      check all(user <- Fixture.user_generator()) do
        assert {:ok, %User{} = user} = Users.update_user(user, @update_attrs)
        assert user.email == "some updated email"
        assert user.name == "some updated name"
        assert user.provider == "some updated provider"
      end
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = Fixture.generate_user()
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)

      assert user |> Map.drop([:marketing_info]) ==
               Users.get_user!(user.id) |> Map.drop([:marketing_info])
    end

    test "update_user/2 with custom settings creates user settings field in settings table" do
      check all(user <- Fixture.user_generator()) do
        # assert nil == Repo.get(Settings, user.id)
        Users.update_user(user, %{"settings" => %{"custom_setting" => 0}})

        assert Repo.get!(Settings, user.id).settings["custom_setting"] == 0
      end
    end

    test "update_user/2 adding custom settings updates user settings field in settings table" do
      check all(user <- Fixture.user_generator()) do
        Users.update_user(user, %{"settings" => %{"custom_setting" => 0}})
        Users.update_user(user, %{"settings" => %{"custom_setting" => 1}})
        Users.update_user(user, %{"settings" => %{"new_custom_setting" => 1}})

        assert Repo.get!(Settings, user.id).settings["custom_setting"] == 1
        assert Repo.get!(Settings, user.id).settings["new_custom_setting"] == 1
      end
    end
  end

  describe "delete" do
    test "delete_user/1 deletes the user" do
      check all(user <- Fixture.user_generator()) do
        Users.update_user(user, %{})
        assert {:ok} == Users.delete_user(user)
        assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
      end
    end

    test "delete_user/1 deletes the user settings" do
      check all(user <- Fixture.user_generator()) do
        Users.update_user(user, %{"settings" => %{"custom_setting" => 0}})

        assert {:ok} == Users.delete_user(user)
        assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
        assert_raise Ecto.NoResultsError, fn -> Repo.get!(Settings, user.id) end
      end
    end
  end

  test "change_user/1 returns a user changeset" do
    check all(user <- Fixture.user_generator()) do
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
