defmodule Scout.Repo.Migrations.AddSurveyQuestionsTable do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :survey_id, references(:surveys, type: :uuid, on_delete: :delete_all)
      add :display_index, :integer, null: false
      add :question, :text, null: false
      add :answer_format, :string, default: "text" # may also be :check, :select, :radio
      add :options, :jsonb
      timestamps()
    end

    create index(:questions, [:survey_id])
  end
end
