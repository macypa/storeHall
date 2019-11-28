defmodule StoreHall.FileUploader do
  use Arc.Definition

  # Include ecto support (requires package arc_ecto installed):
  # use Arc.Ecto.Definition

  def __storage, do: Arc.Storage.Local

  @versions [:image, :thumb]
  @acl :public_read

  @extension_whitelist ~w(.jpg .jpeg .gif .png)
  def extension_whitelist, do: @extension_whitelist

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end

  def transform(:thumb, _) do
    {:magick, " -strip -thumbnail 150x150^ -gravity center -extent 150x150 -format png"}
  end

  def filename(version, {file, item}) do
    # name =
    #   item.details["tags"]
    #   |> Enum.map(fn x -> String.replace(x, ~r".*\/", "") end)
    #   |> Enum.join("-")

    slug =
      Slug.slugify(
        file.file_name
        |> String.replace(~r"\..*", "")
        |> String.replace(~r"[^A-Za-z0-9-]+", "-"),
        ignore: "-"
      )

    # case name do
    #   "" -> "#{version}-#{slug}"
    #   name -> "#{version}-#{name}-#{slug}"
    # end

    # "#{version}-#{file.file_name |> String.replace(~r"\..*", "")}"
    "#{version}-#{slug}"
  end

  def storage_dir(_, {_file, item}) do
    "uploads/#{item.user_id}/#{item.id}"
  end

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Whitelist file extensions:
  # def validate({file, _}) do
  #   ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  # end

  # Define a thumbnail transformation:
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  # end

  # Override the persisted filenames:
  # def filename(version, _) do
  #   version
  # end

  # Override the storage directory:
  # def storage_dir(version, {file, scope}) do
  #   "uploads/user/avatars/#{scope.id}"
  # end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
