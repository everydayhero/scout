defmodule Scout.Question do
  use Ecto.Schema
  alias Ecto.Changeset

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id

  schema "questions" do
    belongs_to :survey, Scout.Survey
    field :display_index, :integer
    field :question, :string
    field :answer_format, :string
    field :options, {:array, :string}
    timestamps()
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
