defmodule Scout.Commands.CreateSurvey do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  use Ecto.Schema

  alias Ecto.{Changeset, Multi}
  alias Scout.Commands.{CreateSurvey, EmbeddedQuestion}
  alias Scout.Util.ValidationHelpers
  alias Scout.Survey

  @primary_key false
  embedded_schema do
    field :owner_id, :string
    field :name, :string
    embeds_many :questions, EmbeddedQuestion
  end

  @doc """
  Create a new CreateSurvey struct from string-keyed map of params
  If validations fails, result is `{:error, %Changeset{}}`, otherwise returns {:ok, %CreateSurvey{}}
  """
  def new(params) do
    changeset = validate(params)
    if changeset.valid? do
      {:ok, Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end

  defp validate(params) do
    %CreateSurvey{}
    |> Changeset.cast(params, [:owner_id, :name])
    |> Changeset.validate_required([:owner_id, :name])
    |> Changeset.validate_change(:owner_id, &ValidationHelpers.validate_uuid/2)
    |> Changeset.cast_embed(:questions, required: true, with: &EmbeddedQuestion.validate_question/2)
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
