defmodule Scout.Survey do
  use Ecto.Schema
  alias Ecto.Changeset

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "surveys" do
    field :owner_id, :binary_id
    field :name, :string
    field :state, :string
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    timestamps()

    has_many :questions, Scout.Question
  end

  def insert_changeset(cmd = %Scout.Survey.Create{}) do
    survey_params = %{
      owner_id: cmd.owner_id,
      name: cmd.name,
      state: "design"
    }

    questions =
      for {val, idx} <- Enum.with_index(cmd.questions) do
        val
        |> Map.from_struct()
        |> Map.put(:display_index, idx)
      end

    %Scout.Survey{}
    |> Changeset.change(survey_params)
    |> Changeset.unique_constraint(:name)
    |> Changeset.put_assoc(:questions, questions)
  end
end
