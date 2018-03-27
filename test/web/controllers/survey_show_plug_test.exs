defmodule Scout.Web.SurveyShowPlugTest do
  use Scout.Web.ConnCase, async: true

  setup do
    survey = %Scout.Survey{
      owner_id: Ecto.UUID.generate(),
      name: "hello"
    }

    %{survey: Scout.Repo.insert!(survey)}
  end

  test "Show with invalid survey ID is 422", %{conn: conn} do
    conn = get(conn, survey_path(conn, :show, "not-a-uuid"))

    assert json_response(conn, 422) == %{
             "errors" => %{"id" => ["Is not a valid UUID"]}
           }
  end

  test "Show with missing auth header is 401", %{conn: conn, survey: survey} do
    conn = get(conn, survey_path(conn, :show, survey.id))

    assert json_response(conn, 401) == %{
             "errors" => %{"user" => ["Unauthorized"]}
           }
  end

  test "Show with invalid auth header is 403", %{conn: conn, survey: survey} do
    conn =
      conn
      |> put_req_header("authorization", "the-wront-value")
      |> get(survey_path(conn, :show, survey.id))

    assert json_response(conn, 403) == %{
             "errors" => %{"user" => ["Forbidden"]}
           }
  end

  test "Show with unknown survey ID is 404", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "123")
      |> get(survey_path(conn, :show, Ecto.UUID.generate()))

    assert json_response(conn, 404) == %{
             "errors" => %{"id" => "Survey not found"}
           }
  end

  test "Show a survey", %{conn: conn, survey: survey} do
    conn =
      conn
      |> put_req_header("authorization", "123")
      |> get(survey_path(conn, :show, survey.id))

    assert json_response(conn, 200) == %{
             "finished_at" => nil,
             "name" => "hello",
             "response_count" => 0,
             "started_at" => nil,
             "state" => "design"
           }
  end
end
