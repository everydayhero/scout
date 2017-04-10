defmodule Scout.Commands.RenameSurvey do
  @moduledoc """
  Defines the schema and validations for a RenameSurvey command.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Util.ValidationHelpers

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :name, :string
  end

  @doc """
  Create a new RenameSurvey struct from string-keyed map of params

  If validations fails, result is `{:error, errors}`, otherwise returns {:ok, struct}
   - "id" is required and must b a uuid
   - "name" is required

  returns {:error, errors} on validation failure, {:ok, struct} otherwise.
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
    |> Changeset.cast(params, [:id, :name])
    |> Changeset.validate_required([:id, :name])
    |> Changeset.validate_change(:id, &ValidationHelpers.validate_uuid/2)
  end
end
