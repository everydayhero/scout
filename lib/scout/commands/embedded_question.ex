defmodule Scout.Commands.EmbeddedQuestion do
  @moduledoc """
  Defines the schema and validations for a survey question that may be embedded within another command.
  """

  use Scout.Commands.Command

  command do
    attr :question, :string, required: true
    attr :answer_format, :string, required: true
    attr :options, {:array, :string}

    validate &validate_options/1
  end

  @doc """
  Custom validation function for the `options` key in a question params map.

  For checkbox questions, there must be at least one options
  For Radio/Select questions, there must be at least two options
  Otherwise (free text), no options validation applies
  """
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
