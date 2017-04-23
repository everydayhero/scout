defmodule Scout.Core.Test do
  use Scout.DataCase, async: true

  @create_params %{
    "name" => "my survey",
    "owner_id" => "3345c1b0-6b91-4fdb-bd90-7c584f7e90eb",
    "questions" => [
      %{"question" => "Marvel or DC?", "answer_format" => "radio", "options" => ["Marvel", "DC"]},
      %{"question" => "Daytime phone number", "answer_format" => "text"}
    ]
  }

  def fixture(:survey, params \\ []) do
    {:ok, %{survey: survey}} = Scout.Core.create_survey(Map.merge(@create_params, Map.new(params)))
    survey
  end

  describe "Create survey" do
    test "with valid params" do
      {:ok, %{survey: survey}} = Scout.Core.create_survey(@create_params)
      assert %{
        name: "my survey",
        owner_id: "3345c1b0-6b91-4fdb-bd90-7c584f7e90eb",
      } = survey
    end

    test "with invalid params" do
      assert {
        :error,
        %{name: ["can't be blank"],
          owner_id: ["can't be blank"],
          questions: ["can't be blank"]}
     } = Scout.Core.create_survey(%{})
    end
  end

  describe "Find survey by ID" do
    setup do
      %{survey: fixture(:survey, %{"name" => "find by ID survey"})}
    end

    test "with valid ID", %{survey: %{id: id}} do
      {:ok, survey} = Scout.Core.find_survey_by_id(id)
      assert %Scout.Survey{id: ^id, name: "find by ID survey"} = survey
    end

    test "with invalid ID" do
      assert {:error, "Survey not found"} = Scout.Core.find_survey_by_id(Ecto.UUID.generate())
    end
  end

  describe "Search for survey" do
    setup do
      fixture(:survey, %{"owner_id" => "3345c1b0-6b91-4fdb-bd90-7c584f7e90eb", "name" => "AA"})
      fixture(:survey, %{"owner_id" => "3345c1b0-6b91-4fdb-bd90-7c584f7e90eb", "name" => "AB"})
      fixture(:survey, %{"owner_id" => "c522e0e7-712c-4b67-9c6e-38820f7ad2e5", "name" => "BB"})
      :ok
    end

    test "by owner" do
      results = Scout.Core.find_surveys(%{"owner" => "3345c1b0-6b91-4fdb-bd90-7c584f7e90eb"})
      assert ["AA", "AB"] = (results |> Enum.map(&Map.get(&1, :name)) |> Enum.sort())
    end

    test "by name" do
      results = Scout.Core.find_surveys(%{"name" => "A%"})
      assert ["AA", "AB"] = (results |> Enum.map(&Map.get(&1, :name)) |> Enum.sort())
    end

    test "with invalid params" do
      assert {:error, details} = Scout.Core.find_surveys(%{"not-a-valid-param" => 12345})
      assert %{"not-a-valid-param" => "invalid parameter"} = details
    end
  end

  describe "Rename survey" do
    setup do
      %{survey: fixture(:survey, %{"name" => "Original Name"})}
    end

    test "to a new name", %{survey: %{id: id}} do
      rename_params = %{"id" => id, "name" => "Renamed"}
      assert {:ok, %{survey: %{name: "Renamed"}}} = Scout.Core.rename_survey(rename_params)
    end

    test "to a name that is taken", %{survey: %{id: id}} do
      fixture(:survey, %{"name" => "Taken"})
      rename_params = %{"id" => id, "name" => "Taken"}
      assert {:error, %{name: ["has already been taken"]}} = Scout.Core.rename_survey(rename_params)
    end
  end

  describe "Add survey response" do
    setup do
      require Ecto.Query, as: Query
      survey = fixture(:survey)
      {1, nil} = Scout.Repo.update_all(Query.where(Scout.Survey, ^[id: survey.id]), set: [state: "running"])
      %{survey: survey}
    end

    test "with valid params", %{survey: survey = %{id: id}} do
      response_params = %{
        "survey_id" => survey.id,
        "respondant_email" => "Reece.Pondant@gmail.com",
        "answers" => ["DC"]
      }
      assert {:ok, %{response: response}} = Scout.Core.add_survey_response(response_params)
      assert %{
        survey_id: ^id,
        respondant_email: "Reece.Pondant@gmail.com"
      } = response
    end

    test "with invalid survey id" do
      response_params = %{
        "survey_id" => Ecto.UUID.generate(),
        "respondant_email" => "Reece.Pondant@gmail.com",
        "answers" => ["DC"]
      }
      assert {:error, "Survey not found"} = Scout.Core.add_survey_response(response_params)
    end

    test "when respondant already responded", %{survey: %{id: id}} do
      response_params = %{
        "survey_id" => id,
        "respondant_email" => "Reece.Pondant@gmail.com",
        "answers" => ["DC"]
      }
      assert {:ok, _} = Scout.Core.add_survey_response(response_params)
      assert {:error, details} = Scout.Core.add_survey_response(response_params)
      assert %{response: %{respondant_email: ["has already been taken"]}} = details
    end
  end
end
