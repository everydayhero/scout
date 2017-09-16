defmodule Scout.Commands.CreateSurvey do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  use Scout.Commands.Command

  alias Ecto.Multi
  alias Scout.Commands.{CreateSurvey, EmbeddedQuestion}
  alias Scout.Util.ValidationHelpers
  alias Scout.Survey

  command do
    attr :owner_id, :string, required: true, validate: &ValidationHelpers.validate_uuid/2
    attr :name, :string, required: true
    many :questions, EmbeddedQuestion, required: true
  end

  @doc """
  Runs a CreateSurvey command

  Returns an Ecto.Multi representing the operation/s that must happen to create a new Survey.
  The multi should be run by the callng code using Repo.transaction or merged into a larger Multi as needed.
  """
  def run(cmd = %CreateSurvey{}) do
    Multi.new()
    |> Multi.insert(:survey, Survey.insert_changeset(cmd))
  end
end
