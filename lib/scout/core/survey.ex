defmodule Scout.Survey do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Survey
  alias Scout.Commands.{CreateSurvey, RenameSurvey}

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "surveys" do
    field :owner_id, :binary_id
    field :name, :string
    field :state, :string
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :response_count, :integer
    field :version, :integer, default: 1
    timestamps()

    has_many :questions, Scout.Question
    has_many :responses, Scout.Response
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

  def increment_response_count_changeset(survey = %Survey{response_count: count, state: state}) do
    survey
    |> Changeset.optimistic_lock(:version)
    |> Changeset.change(response_count: count+1)
    |> validate_survey_running(state)
  end

  defp validate_survey_running(changeset, "running"), do: changeset
  defp validate_survey_running(changeset, _) do
    Changeset.add_error(changeset, :state, "Survey is not running")
  end

  def increment_response_count_query(id: id) do
    require Ecto.Query
    Ecto.Query.from(
      Survey,
      where: [id: ^id],
      update: [inc: [response_count: 1],
               inc: [version: 1]])
  end
end
