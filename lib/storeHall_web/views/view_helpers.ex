defmodule StoreHallWeb.ViewHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  alias StoreHall.Users
  alias StoreHallWeb.AuthController

  def get_logged_user_id(conn) do
    AuthController.get_logged_user_id(conn)
  end

  def is_logged_user?(conn, user_id) do
    logged_user_id = get_logged_user_id(conn)

    logged_user_id != nil and logged_user_id == user_id
  end

  def get_user_image(user) do
    Users.get_user_image(user)
  end

  def get_logged_user_image(conn) do
    AuthController.get_logged_user_image(conn)
  end

  def get_logged_user_unread_mails(conn) do
    AuthController.get_logged_user_unread_mails(conn)
  end

  def obfuscate(data) when is_binary(data) do
    data
    |> String.replace(~r"\.", "|dot|")
    |> String.replace(~r"@", "|at|")
  end

  def obfuscate(data), do: data

  def obfuscate_data(nil, data_name), do: obfuscate(data_name)
  def obfuscate_data("", data_name), do: obfuscate(data_name)
  def obfuscate_data(data, _data_name), do: obfuscate(data)

  def get_thumb_image("//" <> image), do: image_service_link(image)
  def get_thumb_image("http://" <> image), do: image_service_link(image)
  def get_thumb_image("https://" <> image), do: image_service_link(image)

  def get_thumb_image(image), do: image

  defp image_service_link(image) do
    # "//images.weserv.nl/?url=ssl:#{image}&w=450&fit=cover"
    "//#{image}"
  end

  def multi_input_split_key_value(list, key_value_separator \\ ":") do
    list
    |> Enum.map(fn key_value ->
      case key_value do
        k_v when is_binary(k_v) ->
          key_value_splitted = String.split(k_v, key_value_separator, trim: true)

          {key_value_splitted |> hd,
           key_value_splitted |> List.delete_at(0) |> Enum.join(key_value_separator)}

        _ ->
          key_value
      end
    end)
  end

  def sanitize(text), do: sanitize(text, :basic_html)

  def sanitize(nil, _), do: ""

  def sanitize(text, :basic_html) do
    text
    |> HtmlSanitizeEx.basic_html()
    |> String.replace("http://", "https://")
    |> Phoenix.HTML.raw()
  end

  def sanitize(text, :full_html) do
    text
    |> HtmlSanitizeEx.html5()
    |> String.replace("http://", "https://")
    |> Phoenix.HTML.raw()
  end

  def sanitize(text, :strip_tags) do
    text
    |> HtmlSanitizeEx.strip_tags()
    |> String.replace("http://", "https://")
    |> Phoenix.HTML.raw()
  end
end
