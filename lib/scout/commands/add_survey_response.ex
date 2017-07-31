defmodule Scout.Commands.AddSurveyResponse do
  use Scout.Commands.Command

  alias Scout.Commands.AddSurveyResponse
  alias Scout.Util.ValidationHelpers
  alias Scout.{Response, Survey}

  cmd do
    attr :survey_id, :binary_id, [:required, {:custom, &ValidationHelpers.validate_uuid/2}]
    attr :respondant_email, :string, [:required, {:format, ~r/@/}]
    attr :answers, {:array, :string}, [:required]
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
