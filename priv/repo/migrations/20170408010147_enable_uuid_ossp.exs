defmodule Scout.Repo.Migrations.EnableUuidOssp do
  use Ecto.Migration

  # if your `postgres` account isn't superuser, open psql and run: ALTER USER postgres WITH SUPERUSER;
  def up do
    execute ~s[CREATE EXTENSION IF NOT EXISTS "uuid-ossp"]
  end

  def down do
  end

end
