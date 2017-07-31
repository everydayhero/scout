defmodule Scout.Commands.AddSurveyResponse do
  use Ecto.Schema

  alias Ecto.{Changeset, Multi}
  alias Scout.Commands.AddSurveyResponse
  alias Scout.Util.ValidationHelpers
  alias Scout.{Response, Survey}

  @primary_key false
  embedded_schema do
    field :survey_id, :binary_id
    field :respondant_email, :string
    field :answers, {:array, :string}
  end

  @doc """
  Casts and validates params to build an `AddSurveyResponse` struct.

  Returns {:ok, %AddSurveyResponse{}} on success, {:error, %Changeset{}} otherwise.
  """
  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %AddSurveyResponse{}
    |> Changeset.cast(params, [:survey_id, :respondant_email, :answers])
    |> Changeset.validate_required([:survey_id, :respondant_email, :answers])
    |> Changeset.validate_change(:survey_id, &ValidationHelpers.validate_uuid/2)
    |> Changeset.validate_format(:respondant_email, ~r/@/)
  end

  @doc """
  Runs an AddSurveyResponse command.

  Returns an Ecto.Multi representing the operation/s that must happen record the survey response.
  The multi should be run by the callng code using Repo.transaction or merged into a larger Multi as needed.
  """
  def run(cmd = %AddSurveyResponse{survey_id: id}, survey = %Survey{id: id}) do
    Multi.new()
    |> Multi.insert(:response, Response.insert_changeset(cmd))
    |> Multi.update(:survey, Survey.increment_response_count_changeset(survey))
  end
end
