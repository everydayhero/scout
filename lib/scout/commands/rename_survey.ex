defmodule Scout.Commands.RenameSurvey do
  @moduledoc """
  Defines the schema and validations for a RenameSurvey command.
  """

  use Scout.Commands.Command

  alias Scout.Commands.RenameSurvey
  alias Scout.Util.{ErrorHelpers, ValidationHelpers}
  alias Scout.{Repo, Survey, SurveyQuery}

  command do
    attr :id, :binary_id, required: true, validate: &ValidationHelpers.validate_uuid/2
    attr :name, :string, required: true
  end

  @doc """
  Runs a RenameSurvey command in a transaction.

  Returns {:ok, %{survey: %Survey{}}} on sucess, {:error, errors} otherwise.

  This implementation demonstrates the usage of Repo.transaction and Repo.rollback

  Unlike the `CreateSurvey` and `AddSurveyResponse` commands, this command module interacts with
  the repo directly so that it can manage the transaction scope.
  """
  def run(cmd = %RenameSurvey{}) do
    Repo.transaction fn ->
      with survey = %Survey{} <- Repo.one(SurveyQuery.for_update(id: cmd.id)),
           changeset <- Survey.rename_changeset(survey, cmd),
           {:ok, survey} <- Repo.update(changeset) do
        %{survey: survey}
      else
        {:error, changeset} -> Repo.rollback(ErrorHelpers.changeset_errors(changeset))
      end
    end
  end
end
