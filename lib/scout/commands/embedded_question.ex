defmodule Scout.Commands.EmbeddedQuestion do
  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :question, :string
    field :answer_format, :string
    field :options, {:array, :string}
  end

  def validate_question(schema, params) do
    schema
    |> Changeset.cast(params, [:question, :answer_format, :options])
    |> Changeset.validate_required([:question, :answer_format])
    |> validate_options()
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
