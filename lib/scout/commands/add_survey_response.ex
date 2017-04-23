  defmodule Scout.Commands.AddSurveyResponse do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Scout.Commands.AddSurveyResponse
  alias Scout.Util.ValidationHelpers
  alias Scout.Response
  alias Scout.Survey

  @primary_key false
  embedded_schema do
    field :survey_id, :binary_id
    field :respondant_email, :string
    field :answers, {:array, :string}
  end

  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %__MODULE__{}
    |> Changeset.cast(params, [:survey_id, :respondant_email, :answers])
    |> Changeset.validate_required([:survey_id, :respondant_email, :answers])
    |> Changeset.validate_change(:survey_id, &ValidationHelpers.validate_uuid/2)
    |> Changeset.validate_format(:respondant_email, ~r/@/)
  end

  def run(cmd = %AddSurveyResponse{survey_id: id}, survey = %Survey{id: id}) do
    Multi.new()
    |> Multi.insert(:response, Response.insert_changeset(cmd))
    |> Multi.update(:survey, Survey.increment_response_count_changeset(survey))
    # |> Multi.update_all(:survey2, Survey.increment_response_count_query(id: survey.id), [])
  end
end
