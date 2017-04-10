defmodule Scout.Repo.Migrations.AddSurveyResponseCountField do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :response_count, :integer, null: false, default: 0
    end
  end
end
