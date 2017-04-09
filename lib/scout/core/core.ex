defmodule Scout.Core do
  alias Scout.Repo
  alias Scout.Survey
  alias Scout.Util.ErrorHelpers

  def create_survey(params) do
    with {:ok, cmd} <- Scout.Survey.Create.new(params),
         changeset = %{valid?: true} <- Survey.insert_changeset(cmd),
         {:ok, survey} <- Repo.insert(changeset) do
      {:ok, survey}
    else
      {:error, changeset} -> {:error, ErrorHelpers.changeset_errors(changeset)}
    end
  end

  def find_surveys(query_params) do
    query_params
    |> Scout.Survey.Query.build()
    |> Repo.all()
  end
end
