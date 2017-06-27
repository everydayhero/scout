defmodule Scout.Web.SurveyShowPlug do
  use Plug.Builder
  alias Plug.Conn
  import Plug.Conn, only: [put_resp_content_type: 2]

  plug :put_resp_content_type, "application/json"
  plug :validate
  plug :authorize
  plug :query
  plug :respond

  @doc "Function plug to validate a GET /surveys/:id request"
  def validate(conn = %Conn{params: %{"id" => id}}, _opts) do
    with [] <- Scout.Util.ValidationHelpers.validate_uuid(:id, id) do
      Conn.assign conn, :survey_id, id
    else
      [id: error_msg] ->
        conn
        |> Conn.send_resp(422, Poison.encode! %{errors: %{id: [error_msg]}})
        |> Conn.halt()
    end
  end

  @doc "Function plug to authorize the current user for accessing GET /surveys/:id request"
  def authorize(conn = %Conn{assigns: %{survey_id: _id}}, _opts) do
    with ["123"] <- Conn.get_req_header(conn, "authorization") do
      Conn.assign conn, :user_id, 123
    else
      [] ->
        conn
        |> Conn.send_resp(401, Poison.encode! %{errors: %{user: ["Unauthorized"]}})
        |> Conn.halt()
      _ ->
        conn
        |> Conn.send_resp(403, Poison.encode! %{errors: %{user: ["Forbidden"]}})
        |> Conn.halt()
    end
  end

  @doc "Function plug to load a survey by ID from the database"
  def query(conn = %Conn{assigns: %{survey_id: id}}, _opts) do
    with {:ok, survey} <- Scout.Core.find_survey_by_id(id) do
      Conn.assign conn, :survey, survey
    else
      {:error, reason} ->
        conn
        |> Conn.send_resp(404, Poison.encode! %{errors: reason})
        |> Conn.halt()
    end
  end

  @doc "Function plug to serialize a Survey to JSON and respond"
  def respond(conn = %Conn{assigns: %{survey: survey}}, _opts) do
    response = %{
      name: survey.name,
      state: survey.state,
      started_at: survey.started_at,
      finished_at: survey.finished_at,
      response_count: survey.response_count
    }
    Conn.send_resp(conn, 200, Poison.encode!(response))
  end
end
