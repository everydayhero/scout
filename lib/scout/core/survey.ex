defmodule Scout.Survey do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Survey
  alias Scout.Commands.RenameSurvey
  alias Scout.Commands.CreateSurvey

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

  @doc """
  Given a validated CreateSurvey struct, creates a changeset that will insert a new Survey in the database.
  Note that the unique constraint on `name` may still cause a failure in Repo.insert.
  """
  def insert_changeset(cmd = %CreateSurvey{}) do
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

    %Survey{}
    |> Changeset.change(survey_params)
    |> Changeset.unique_constraint(:name)
    |> Changeset.put_assoc(:questions, questions)
  end

  @doc """
  Given a validated UpdateSurvey struct, creates a changeset that will rename the survey
  """
  def rename_changeset(survey = %Survey{id: id}, %RenameSurvey{id: id, name: name}) do
    survey
    |> Changeset.change(name: name)
    |> Changeset.unique_constraint(:name)
  end
end
