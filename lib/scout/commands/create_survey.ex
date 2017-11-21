defmodule Scout.Commands.CreateSurvey do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  defmodule Question do
    use Scout.Commands.Command

    command_component do
      attr :question, :string, required: true
      attr :answer_format, :string, required: true
      attr :options, {:array, :string}

      validate &validate_options/1
    end

    def validate_options(cs = %Changeset{}) do
      case Changeset.get_field(cs, :answer_format) do
        "check" ->
          cs
          |> Changeset.validate_required(:options)
          |> Changeset.validate_length(:options, min: 1)
        fmt when fmt in ["select", "radio"] ->
          cs
          |> Changeset.validate_required(:options)
          |> Changeset.validate_length(:options, min: 2)
        _ -> cs
      end
    end
  end

  use Scout.Commands.Command

  alias Ecto.Multi
  alias Scout.Util.ValidationHelpers
  alias Scout.Survey

  command do
    attr :owner_id, :string, required: true, validate: &ValidationHelpers.validate_uuid/2
    attr :name, :string, required: true
    many :questions, Question, required: true
  end

  @doc """
  Runs a CreateSurvey command

  Returns an Ecto.Multi representing the operation/s that must happen to create a new Survey.
  The multi should be run by the callng code using Repo.transaction or merged into a larger Multi as needed.
  """
  def run(cmd = %__MODULE__{}) do
    Multi.new()
    |> Multi.insert(:survey, Survey.insert_changeset(cmd))
  end
end
