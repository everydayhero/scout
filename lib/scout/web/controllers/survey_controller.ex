defmodule Scout.Web.SurveyController do
  use Scout.Web, :controller

  def create(conn, params) do
    with {:ok, survey} <- Scout.Core.create_survey(params) do
      conn
      |> Plug.Conn.put_status(201)
      |> Phoenix.Controller.json(Map.from_struct(survey))
    else
      {:error, errors} ->
        conn
        |> Plug.Conn.put_status(422)
        |> Phoenix.Controller.json(%{errors: errors})
    end
  end
end
