defmodule Scout.Web.SurveyView do
  use Scout.Web.View

  alias Phoenix.View
  alias Scout.{Question, Survey}
  alias Scout.Web.SurveyView

  def render("show.json", %{survey: survey = %Survey{}}) do
    %{
      id: survey.id,
      name: survey.name,
      owner_id: survey.owner_id,
      state: survey.state,
      started_at: survey.started_at,
      finished_at: survey.finished_at,
      response_count: survey.response_count,
      questions: View.render_many(survey.questions, SurveyView, "question.json", as: :question)
    }
  end

  def render("question.json", %{question: question = %Question{}}) do
    %{
      question: question.question,
      answer_format: question.answer_format,
      options: question.options
    }
  end
end
