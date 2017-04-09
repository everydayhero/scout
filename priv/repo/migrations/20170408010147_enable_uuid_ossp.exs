defmodule Scout.Repo.Migrations.EnableUuidOssp do
  use Ecto.Migration

  def up do
    execute ~s[CREATE EXTENSION IF NOT EXISTS "uuid-ossp"]
  end

  def down do
  end

end
