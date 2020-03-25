defmodule StoreHallWeb.ViewHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  alias StoreHallWeb.AuthController

  def get_logged_user_id(conn) do
    AuthController.get_logged_user_id(conn)
  end

  def is_logged_user?(conn, user_id) do
    logged_user_id = get_logged_user_id(conn)

    logged_user_id != nil and logged_user_id == user_id
  end

  def get_logged_user_image(conn) do
    AuthController.get_logged_user_image(conn)
  end

  def obfuscate(data) do
    data
    |> String.replace(~r"\.", "|dot|")
    |> String.replace(~r"@", "|at|")
  end

  def obfuscate_data(nil, data_name), do: obfuscate(data_name)
  def obfuscate_data("", data_name), do: obfuscate(data_name)
  def obfuscate_data(data, _data_name), do: obfuscate(data)
end
