defmodule StoreHall.FileUploader do
  use Arc.Definition

  # Include ecto support (requires package arc_ecto installed):
  # use Arc.Ecto.Definition

  def __storage, do: Arc.Storage.Local

  @versions [:image, :thumb]
  @acl :public_read

  @extension_whitelist ~w(.jpg .jpeg .png .gif .webp)
  def extension_whitelist, do: @extension_whitelist

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end

  def transform(:thumb, {%Arc.File{file_name: _file_name}, _}) do
    {
      :magick,
      fn input, output ->
        "#{input}[0] -strip -thumbnail X250\> -background none -gravity center -format jpg #{
          output
        }"
      end
    }
  end

  def transform(:image, {%Arc.File{file_name: file_name}, _}) do
    case file_name |> String.ends_with?(".gif") do
      true ->
        :noaction

      false ->
        {
          :magick,
          "-strip -resize X700\> -background none -depth 8 -quality 75 -density 72 -units pixelsperinch -format jpg"
        }
    end
  end

  def filename(version, {file, _item}) do
    slug =
      Slug.slugify(
        file.file_name
        |> String.replace(~r"\..*", "")
        |> String.replace(~r"[^A-Za-z0-9-]+", "-"),
        ignore: "-"
      )

    "#{version}-#{slug}"
  end

  def storage_dir(_, {_file, item = %StoreHall.Items.Item{}}) do
    "uploads/#{item.user_id}/#{item.id}"
  end

  def storage_dir(_, {_file, user = %StoreHall.Users.User{}}) do
    "uploads/#{user.id}"
  end
end
