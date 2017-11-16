defmodule Scout.Response do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Response
  alias Scout.Commands.AddSurveyResponse

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id

  schema "responses" do
    belongs_to(:survey, Scout.Survey)
    field(:respondant_email, :string)
    field(:answers, {:array, :string})
    timestamps()
  end

  def insert_changeset(cmd = %AddSurveyResponse{}) do
    response_params = Map.take(cmd, [:survey_id, :respondant_email, :answers])
    index_name = :responses_survey_id_respondant_email_index

    %Response{}
    |> Changeset.change(response_params)
    |> Changeset.unique_constraint(:respondant_email, name: index_name)
  end
end
