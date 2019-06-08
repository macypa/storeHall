defmodule StoreHall.ChatsTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Chats

  describe "item chats" do
    test "for_item/1 returns all chats" do
      user = Fixture.generate_user()
      item = Fixture.generate_item(user)

      check all author <- Fixture.user_generator() do
        item_chats_count = length(Chats.for_item(item.id, user.id))

        Chats.create_chat_message(%{
          "item_id" => item.id,
          "owner_id" => item.user_id,
          "user_id" => item.user_id,
          "author_id" => author.id,
          "details" => %{"scores" => %{"clean" => "3"}}
        })

        assert length(Chats.for_item(item.id, user.id)) == item_chats_count + 1
      end
    end

    test "for_user/1 returns all chats" do
      user = Fixture.generate_user()

      check all author <- Fixture.user_generator() do
        user_chats_count = length(Chats.for_user(user.id, user.id))

        Chats.create_chat_message(%{
          "user_id" => user.id,
          "owner_id" => user.id,
          "author_id" => author.id,
          "details" => %{"scores" => %{"clean" => "3"}}
        })

        assert length(Chats.for_user(user.id, user.id)) == user_chats_count + 1
      end
    end
  end
end
