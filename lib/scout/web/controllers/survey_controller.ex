defmodule Scout.Web.SurveyController do
  use Scout.Web.Controller

  alias Scout.Web.SurveyView
  alias Plug.Conn
  alias Phoenix.Controller

  def create(conn, params) do
    with {:ok, %{survey: survey}} <- Scout.Core.create_survey(params) do
      conn
      |> Conn.put_status(201)
      |> Controller.render(SurveyView, :show, survey: survey)
    else
      {:error, errors} ->
        conn
        |> Conn.put_status(422)
        |> Controller.json(%{errors: errors})
    end
  end
end
