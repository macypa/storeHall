defmodule StoreHallWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use StoreHallWeb, :controller
      use StoreHallWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: StoreHallWeb

      import Plug.Conn
      import StoreHallWeb.Gettext
      alias StoreHallWeb.Router.Helpers, as: Routes
      alias StoreHallWeb.Gettext, as: Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/storeHall_web/templates",
        namespace: StoreHallWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      use Timex

      import StoreHallWeb.ErrorHelpers
      import StoreHallWeb.ViewHelpers
      import StoreHallWeb.Gettext
      alias StoreHallWeb.Router.Helpers, as: Routes
      alias StoreHallWeb.Gettext, as: Gettext

      def render_shared(template, assigns \\ []) do
        render(StoreHallWeb.SharedView, template, assigns)
      end

      def timex_time(ecto_time) do
        case ecto_time do
          "{{inserted_at}}" ->
            "{{inserted_at}}"

          "{{updated_at}}" ->
            "{{updated_at}}"

          ecto_time ->
            ecto_time
            |> Timex.format!("{D}.{M}.{YYYY} {h24}:{m}")
        end
      end
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import StoreHallWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
