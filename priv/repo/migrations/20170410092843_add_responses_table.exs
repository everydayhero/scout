defmodule Scout.Repo.Migrations.AddResponsesTable do
  use Ecto.Migration

  def change do
    create table(:responses) do
      add :survey_id, references(:surveys, type: :uuid, on_delete: :delete_all)
      add :respondant_email, :string, required: true
      add :answers, :jsonb, required: true
      timestamps()
    end

    create index(:responses, [:survey_id])
    create index(:responses, [:respondant_email])
    create unique_index(:responses, [:survey_id, :respondant_email])
  end
end
