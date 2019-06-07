defmodule StoreHall.ImagesTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items
  alias StoreHall.FileUploader

  describe "images" do
    test "fileUploader url uses tags from item" do
      check all item <- Fixture.item_generator(),
                image <- StreamData.string(:alphanumeric) do
        image_url = FileUploader.url({image, item})

        assert item.details["tags"]
               |> Enum.each(fn tag ->
                 assert String.contains?(image_url, tag)
               end)

        assert String.match?(image_url, ~r'/#{item.user_id}/#{item.id}/image-')
        refute String.match?(image_url, ~r'[^A-Za-z0-9-/]')
      end
    end

    @tag :skip
    test "cover image of nonexisting images is empty string" do
      check all item <- Fixture.item_generator() do
        cover_img_url = Items.cover_image(item)

        assert cover_img_url == ""
      end
    end
  end
end
