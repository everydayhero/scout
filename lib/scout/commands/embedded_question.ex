defmodule Scout.Commands.EmbeddedQuestion do
  @moduledoc """
  Defines the schema and validations for a survey question that may be embedded within another command.
  """

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :question, :string
    field :answer_format, :string
    field :options, {:array, :string}
  end

  @doc """
  Validation function that may be used in a call to Changeset.cast_assoc, or Changeset.cast_embed
  """
  def validate_question(schema, params) do
    schema
    |> Changeset.cast(params, [:question, :answer_format, :options])
    |> Changeset.validate_required([:question, :answer_format])
    |> validate_options()
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
