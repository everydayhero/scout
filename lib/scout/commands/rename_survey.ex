defmodule Scout.Commands.RenameSurvey do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Util.ValidationHelpers

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :name, :string
  end

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
