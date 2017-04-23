defmodule Scout.Repo.Migrations.AddSurveyVersion do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :version, :integer, null: false, default: 1
    end
  end
end
