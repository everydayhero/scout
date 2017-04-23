defmodule Scout.Web do
  defmodule Controller do
    defmacro __using__(_) do
      quote do
        use Phoenix.Controller, namespace: Scout.Web
      end
    end
  end

  defmodule View do
    defmacro __using__(_) do
      quote do
        use Phoenix.View, root: "lib/scout/web/templates", namespace: Scout.Web
      end
    end
  end
end
