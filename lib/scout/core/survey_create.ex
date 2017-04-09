defmodule Scout.Survey.Create do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Survey.Create

  embedded_schema do
    field :owner_id, :string
    field :name, :string

    embeds_many :questions, Question, primary_key: false do
      field :question, :string
      field :answer_format, :string
      field :options, {:array, :string}
    end
  end

  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %Create{}
    |> Changeset.cast(params, [:owner_id, :name])
    |> Changeset.validate_required([:owner_id, :name])
    |> Changeset.validate_change(:owner_id, &validate_uuid/2)
    |> Changeset.cast_embed(:questions, required: true, with: &validate_question/2)
  end

  defp validate_question(schema, params) do
    schema
    |> Changeset.cast(params, [:question, :answer_format, :options])
    |> Changeset.validate_required([:question, :answer_format])
    |> Scout.Question.validate_options()
  end

  defp validate_uuid(field, val) do
    case Ecto.UUID.cast(val) do
      :error -> [{field, "Is not a valid UUID"}]
      {:ok, _} -> []
    end
  end
end
