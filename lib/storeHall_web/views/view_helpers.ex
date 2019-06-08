defmodule StoreHallWeb.ViewHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  def get_user_id_from_conn(conn) do
    case StoreHallWeb.AuthController.get_user_id_from_conn(conn) do
      -1 -> nil
      id -> id
    end
  end
end
