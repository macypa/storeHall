defmodule StoreHall.Images do
  alias Ecto.Multi
  alias StoreHall.FileUploader

  def append_images(query_result) do
    query_result
    |> Enum.map(fn model ->
      Map.put(
        model,
        :details,
        model.details
        |> put_in(
          ["images"],
          model.details["images"]
          |> Enum.map(fn image ->
            image_url(model, image)
          end)
        )
      )
    end)
  end

  def image_url(model, image, version \\ :thumb) do
    image = StoreHall.FileUploader.url({image, model}, version)

    case String.ends_with?(image, to_string(version) <> "-") do
      false -> image
      true -> ""
    end

    # case File.exists?("." <> image) do
    #   false -> ""
    #   true -> image
    # end
  end

  @cover_image_not_found nil

  def cover_image(model) do
    case model.details["images"] do
      nil -> @cover_image_not_found
      "[]" -> @cover_image_not_found
      "null" -> @cover_image_not_found
      [] -> @cover_image_not_found
      images -> Enum.at(images, 0)
    end
  end

  def prepare_images(model) do
    case model["images"] do
      nil ->
        model

      images ->
        new_images =
          images
          |> Enum.map(fn image ->
            rename_duplicated(image, model).filename
          end)

        model
        |> put_in(["details", "images"], model["details"]["images"] ++ new_images)
    end
  end

  def rename_duplicated(image, model) do
    case Map.get(model, "details")["images"] do
      nil ->
        image

      saved_images ->
        saved_images
        |> Enum.filter(fn saved_image ->
          String.contains?(strip_ext(saved_image), strip_ext(image.filename))
        end)
        |> case do
          [] ->
            image

          similar_images ->
            new_name =
              "#{strip_ext(image.filename)}-#{length(similar_images) + 1}#{
                Path.extname(image.filename)
              }"

            Map.put(image, :filename, new_name)
        end
    end
  end

  defp strip_ext(image_name) do
    image_name |> Path.basename() |> Path.rootname()
  end

  def upsert_images(multi, model, multi_name) do
    case model["images"] do
      nil ->
        multi

      images ->
        multi
        |> Multi.run(:upsert_images, fn _repo, %{^multi_name => model_with_user_id} ->
          images
          |> rename_duplicated(model_with_user_id)
          |> Enum.reduce({:ok, "no error"}, fn image, acc ->
            case FileUploader.store({rename_duplicated(image, model), model_with_user_id}) do
              {:ok, _value} -> acc
              {:error, value} -> {:error, value}
            end
          end)
        end)
    end
  end

  def clean_images(multi, model, images_to_remove) do
    multi
    |> Multi.run(:clean_images, fn _repo, _ ->
      images_to_remove
      |> Enum.reduce({:ok, "no error"}, fn image, _acc ->
        FileUploader.delete({image, model})
      end)

      # File.rmdir(FileUploader.storage_dir(nil, {nil, model}))
      {:ok, "no error"}
    end)
  end
end
