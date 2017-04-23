defmodule Scout.SurveyQuery do
  import Ecto.Query, only: [from: 2]
  require Ecto.Query
  alias Scout.Survey

  def build(params) do
    Enum.reduce_while(params, Scout.Survey, fn
      {"owner", id}, query        -> {:cont, query |> for_owner(id)}
      {"name", pattern}, query    -> {:cont, query |> name_like(pattern)}
      {"state", state}, query     -> {:cont, query |> in_state(state)}
      {"started", "+"<>t}, query  -> {:cont, query |> started_after(t |> DateTime.from_iso8601() |> elem(1))}
      {"finished", "-"<>t}, query -> {:cont, query |> finished_before(t |> DateTime.from_iso8601() |> elem(1))}
      {other, _}, _query          -> {:halt, {:error, %{other => "invalid parameter"}}}
    end)
  end

  def for_update(id: id) do
    from Survey, where: [id: ^id], lock: "FOR UPDATE", preload: :questions
  end

  def for_owner(query, owner_id) do
      from survey in query, where: survey.owner_id == ^owner_id
  end

  def name_like(query, name_pattern) do
    from survey in query, where: like(survey.name, ^name_pattern)
  end

  def in_state(query, state) do
    from survey in query, where: survey.state == ^state
  end

  def started_after(query, start_date) do
    from survey in query, where: survey.started_at > ^start_date
  end

  def finished_before(query, end_date) do
    from survey in query, where: survey.finished_at < ^end_date
  end
end
