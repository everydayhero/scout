defmodule Scout.Core do
  alias Scout.{Repo, Survey, SurveyQuery}
  alias Scout.Commands.{CreateSurvey, RenameSurvey}
  alias Scout.Util.ErrorHelpers

  def create_survey(params) do
    with {:ok, cmd} <- CreateSurvey.new(params),
         changeset = %{valid?: true} <- Survey.insert_changeset(cmd),
         {:ok, survey} <- Repo.insert(changeset) do
      {:ok, survey}
    else
      {:error, changeset} -> {:error, ErrorHelpers.changeset_errors(changeset)}
    end
  end

  def find_surveys(query_params) do
    query_params
    |> SurveyQuery.build()
    |> Repo.all()
  end

  def rename_survey(params) do
    Repo.transaction fn ->
      with {:ok, cmd} <- RenameSurvey.new(params),
           survey = %Survey{} <- Repo.one(SurveyQuery.for_update(id: cmd.id)),
           changeset = %{valid?: true} <- Survey.rename_changeset(survey, cmd),
           {:ok, survey} <- Repo.update(changeset) do
        survey
      else
        {:error, changeset} -> Repo.rollback(ErrorHelpers.changeset_errors(changeset))
      end
    end
  end
end
