defmodule Scout.Repo.Migrations.AddSurveysTable do
  use Ecto.Migration

  def change do
    create table(:surveys, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :owner_id, :uuid, null: false
      add :name, :text, null: false
      add :state, :text, null: false, default: "design" # State machine: design -> running -> complete
      add :started_at, :utc_datetime
      add :finished_at, :utc_datetime
      timestamps()
    end

    create unique_index(:surveys, [:name])
  end

end
