defmodule Scout.Commands.RenameSurvey do
  @moduledoc """
  Defines the schema and validations for a RenameSurvey command.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Commands.RenameSurvey
  alias Scout.Util.{ErrorHelpers, ValidationHelpers}
  alias Scout.{Repo, Survey, SurveyQuery}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :name, :string
  end

  @doc """
  Create a new RenameSurvey struct from string-keyed map of params

  If validations fails, result is `{:error, errors}`, otherwise returns {:ok, struct}
   - "id" is required and must b a uuid
   - "name" is required

  returns {:error, errors} on validation failure, {:ok, struct} otherwise.
  """
  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %RenameSurvey{}
    |> Changeset.cast(params, [:id, :name])
    |> Changeset.validate_required([:id, :name])
    |> Changeset.validate_change(:id, &ValidationHelpers.validate_uuid/2)
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
