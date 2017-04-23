defmodule Scout.Commands.CreateSurvey do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Scout.Commands.EmbeddedQuestion
  alias Scout.Commands.CreateSurvey
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
  If validations fails, result is `{:error, errors}`, otherwise returns {:ok, struct}
  """
  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %__MODULE__{}
    |> Changeset.cast(params, [:owner_id, :name])
    |> Changeset.validate_required([:owner_id, :name])
    |> Changeset.validate_change(:owner_id, &ValidationHelpers.validate_uuid/2)
    |> Changeset.cast_embed(:questions, required: true, with: &EmbeddedQuestion.validate_question/2)
  end

  def run(cmd = %CreateSurvey{}) do
    Multi.new()
    |> Multi.insert(:survey, Survey.insert_changeset(cmd))
  end
end
