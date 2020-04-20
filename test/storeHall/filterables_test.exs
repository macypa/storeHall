defmodule StoreHall.FilterablesTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items
  alias StoreHall.Users
  alias StoreHall.Users.User

  describe "paging" do
    property "filter for users returns all users with page-size = -1" do
      check all(_ <- Fixture.user_generator()) do
        params = %{"page-size" => -1}
        assert length(Users.list_users(params)) <= Repo.all(User)
      end
    end

    property "filter for items returns lessOrEq than page-size" do
      check all(_ <- Fixture.item_generator(), page_size <- StreamData.positive_integer()) do
        params = %{"page-size" => "#{page_size}"}
        assert length(Items.list_items(params)) <= page_size
      end
    end
  end

  describe "sorting" do
    test "filter for users" do
      check all(
              _ <- Fixture.user_generator(),
              sort_field <- StreamData.member_of([:inserted_at, :updated_at])
            ) do
        params = %{"filter" => %{"sort" => Atom.to_string(sort_field)}}

        assert Users.list_users(params) ==
                 Users.list_users(params)
                 |> Enum.sort(
                   &(to_string(Map.get(&1, sort_field)) <= to_string(Map.get(&2, sort_field)))
                 )
      end
    end

    test "filter for items" do
      check all(
              _ <- Fixture.item_generator(),
              sort_field <- StreamData.member_of([:id, :inserted_at, :updated_at])
            ) do
        params = %{"filter" => %{"sort" => Atom.to_string(sort_field)}}

        assert Items.list_items(params) ==
                 Items.list_items(params)
                 |> Enum.sort(
                   &(to_string(Map.get(&1, sort_field)) <= to_string(Map.get(&2, sort_field)))
                 )
      end
    end
  end

  describe "search user" do
    property "by first/last name returns at least one result" do
      check all(user <- Fixture.user_generator()) do
        params = %{"filter" => %{"q" => user.name}}

        assert length(Users.list_users(params)) > 0
      end
    end

    property "by unexisting first/last name returns empty result" do
      check all(_ <- Fixture.user_generator()) do
        params = %{"filter" => %{"q" => "K^&#\{$%!asfw$%$!"}}

        assert length(Users.list_users(params)) == 0
      end
    end
  end

  describe "search item" do
    test "by name/user_id" do
      check all(
              item <- Fixture.item_generator(),
              field <- StreamData.member_of([:name, :user_id])
            ) do
        params = %{"filter" => %{"q" => Map.get(item, field)}}

        filtered = Items.list_items(params)
        assert length(filtered) > 0

        filtered
        |> Enum.each(fn i ->
          assert String.contains?(
                   String.downcase(Map.get(i, :name)) <>
                     String.downcase(Map.get(i, :user_id)) <>
                     String.downcase(to_string(Map.get(i.details, "tags"))) <>
                     String.downcase(to_string(Map.get(i.details, "cities"))) <>
                     String.downcase(to_string(Map.get(i.details, "description"))) <>
                     String.downcase(to_string(Map.get(i.details, "conditions"))) <>
                     String.downcase(to_string(Map.get(i.details, "features"))),
                   String.downcase(Map.get(item, field))
                 )
        end)
      end
    end

    property "by name/user_id returns empty result" do
      check all(_ <- Fixture.item_generator()) do
        params = %{"filter" => %{"q" => "K^&#\{$%!asfw$%$!"}}

        assert length(Items.list_items(params)) == 0
      end
    end

    property "by rating returns results with only lower ratings" do
      check all(item <- Fixture.item_generator()) do
        item_score = item.details["rating"]["score"]
        params = %{"filter" => %{"rating" => %{"min" => to_string(item_score)}}}

        filtered = Items.list_items(params)
        assert length(filtered) > 0

        filtered
        |> Enum.each(fn i ->
          assert i.details["rating"]["score"] >= item_score
        end)

        refute filtered
               |> Enum.find(fn i -> i.details["rating"]["score"] < item_score end)
      end
    end

    #
    property "by rating returns results with only higher ratings" do
      check all(item <- Fixture.item_generator()) do
        item_score = item.details["rating"]["score"]
        params = %{"filter" => %{"rating" => %{"max" => to_string(item_score)}}}

        filtered = Items.list_items(params)
        assert length(filtered) > 0

        filtered
        |> Enum.each(fn i ->
          assert i.details["rating"]["score"] <= item_score
        end)

        refute filtered
               |> Enum.find(fn i -> i.details["rating"]["score"] > item_score end)
      end
    end

    property "by tags returns only with tags that are searched for" do
      check all(item <- Fixture.item_generator()) do
        case item.details["tags"] do
          tags when is_map(tags) ->
            tag = hd(tags)
            params = %{"filter" => %{"tags" => tag}}

            filtered = Items.list_items(params)
            assert length(filtered) > 0

            filtered
            |> Enum.each(fn i ->
              assert i.details["tags"] |> Enum.find(fn t -> t > tag end)
            end)

          _no_tag ->
            assert true
        end
      end
    end

    property "by merchant returns only with merchant that is searched for" do
      check all(item <- Fixture.item_generator()) do
        params = %{"filter" => %{"merchant" => [item.user_id]}}

        filtered = Items.list_items(params)
        assert length(filtered) > 0

        filtered
        |> Enum.each(fn i ->
          assert i.user_id == item.user_id
        end)
      end
    end

    property "with images returns only with images" do
      check all(item <- Fixture.item_generator()) do
        case item.details["images"] do
          images when is_map(images) ->
            params = %{"filter" => %{"with-image" => true}}

            filtered = Items.list_items(params)
            assert length(filtered) > 0

            filtered
            |> Enum.each(fn i ->
              assert i.details["images"] != []
              assert i.details["images"]
            end)

          _no_images ->
            assert true
        end
      end
    end
  end
end
