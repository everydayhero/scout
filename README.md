# Scout

Protoss unit highly skilled at conducting Surveys.

# Getting Started

`phx.new scout --binary-id --no-html --no-brunch`

`cd scout`
`mix ecto.create`
`mix phoenix.server`


# Packages

`mix deps.tree`

```
└── phoenix_ecto ~> 3.2 (Hex package)
    ├── ecto ~> 2.1 (Hex package)
    │   ├── db_connection ~> 1.1 (Hex package)
    │   ├── decimal ~> 1.2 (Hex package)
    │   ├── poison ~> 2.2 or ~> 3.0 (Hex package)
    │   ├── poolboy ~> 1.5 (Hex package)
    │   └── postgrex ~> 0.13.0 (Hex package)
    └── plug ~> 1.0 (Hex package)
```

# Ecto Repo

Repositories are wrappers around the data store.
Via the repository, we can create, update, destroy and query existing entries.
A repository needs an adapter and credentials to communicate to the database

```elixir
# lib/scout/repo.ex
defmodule Scout.Repo do
  use Ecto.Repo, otp_app: :scout

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
```

```elixir
# config/dev.exs
# Configure your database
config :scout, Scout.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "scout_dev",
  hostname: "localhost",
  pool_size: 10
```

```elixir
#lib/scout/application.ex
# Define workers and child supervisors to be supervised
children = [
  # Start the Ecto repository
  supervisor(Scout.Repo, []),
  # Start the endpoint when the application starts
  supervisor(Scout.Web.Endpoint, []),
  # Start your own worker by calling: Scout.Worker.start_link(arg1, arg2, arg3)
  # worker(Scout.Worker, [arg1, arg2, arg3]),
]
```

# Migrations

Migrations are used to modify your database schema over time.

`mix ecto.gen.migration add_surveys_table`

```elixir
# priv/repo/migrations/20170408010215_add_surveys_table.exs
defmodule Scout.Repo.Migrations.AddSurveysTable do
  use Ecto.Migration

  def change do
    create table(:surveys, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :owner_id, :uuid, null: false
      add :name, :string, null: false
      add :state, :string, null: false, default: "design" # State machine: design -> running -> complete
      add :started_at, :utc_datetime
      add :finished_at, :utc_datetime
      timestamps()
    end
  end
end
```

Run the migration
`mix ecto.migrate`

Phoenix adds some helpful aliases by default
```elixir
defp aliases do
  ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
   "ecto.reset": ["ecto.drop", "ecto.setup"],
   "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
end
```

See the generated schema:

`mix ecto.dump`



# Inserting Data

The simplest way to get some data into the DB is to add some code to the seeds.exs script:

`Repo.insert_all` takes a table and a list of maps to insert.
Note that the

```elixir
alias Scout.Repo

survey_owner_id = Ecto.UUID.bingenerate()
now = DateTime.utc_now()

Repo.insert_all("surveys", [
  %{
    owner_id: survey_owner_id,
    name: "Awesome event signup survey",
    state: "design",
    inserted_at: now,
    updated_at: now
  },
  %{
    owner_id: survey_owner_id,
    name: "Awesome event donation survey",
    state: "design",
    inserted_at: now,
    updated_at: now
  }
])
```

`mix ecto.reset`

```
11:47:48.336 [info]  == Migrated in 0.0s
[debug] QUERY OK db=2.3ms
INSERT INTO "surveys" ("inserted_at","name","owner_id","state","updated_at")
VALUES ($1,$2,$3,$4,$5),($6,$7,$8,$9,$10) [
  {{2017, 4, 8}, {1, 47, 48, 426207}},
  "Awesome event signup survey",
  <<157, 201, 231, 176, 190, 40, 70, 171, 166, 255, 229, 119, 23, 110, 232, 99>>,
  "design",
  {{2017, 4, 8}, {1, 47, 48, 426207}},
  {{2017, 4, 8}, {1, 47, 48, 426207}},
  "Awesome event donation survey",
  <<157, 201, 231, 176, 190, 40, 70, 171, 166, 255, 229, 119, 23, 110, 232, 99>>,
  "design",
  {{2017, 4, 8}, {1, 47, 48, 426207}}
]
```

Take a look in psql:

```
psql scout_dev
scout_dev=# \x
scout_dev=# select * from surveys;

-[ RECORD 1 ]-------------------------------------
id          | f68b2258-5135-4f2b-9cf5-94aa3fcec0de
owner_id    | 9dc9e7b0-be28-46ab-a6ff-e577176ee863
name        | Awesome event signup survey
state       | design
started_at  |
finished_at |
inserted_at | 2017-04-08 01:47:48.426207
updated_at  | 2017-04-08 01:47:48.426207
-[ RECORD 2 ]-------------------------------------
id          | 6cac2e49-8ff5-4c4b-8b04-9243e2f24a1f
owner_id    | 9dc9e7b0-be28-46ab-a6ff-e577176ee863
name        | Awesome event donation survey
state       | design
started_at  |
finished_at |
inserted_at | 2017-04-08 01:47:48.426207
updated_at  | 2017-04-08 01:47:48.426207
```

# Basic Querying

Fire up `iex` to run some interactive queries

Direct SQL queries with parameters

```elixir
alias Scout.Repo
require Ecto.Query, as: Query
Repo.query("select * from  surveys where name like $1", ["%donation%"])
{:ok,
 %Postgrex.Result{columns: ["id", "owner_id", "name", "state", "started_at",
   "finished_at", "inserted_at", "updated_at"], command: :select,
  connection_id: 44171, num_rows: 1,
  rows: [[<<220, 157, 250, 158, 126, 201, 76, 107, 177, 86, 84, 155, 188, 189,
      170, 115>>,
    <<50, 38, 151, 203, 190, 79, 67, 118, 129, 67, 53, 253, 182, 14, 121, 14>>,
    "Awesome event donation survey", "design", nil, nil,
    {{2017, 4, 8}, {6, 2, 8, 320861}}, {{2017, 4, 8}, {6, 2, 8, 320861}}]]}}
```

However, the Query DSL allows for safely interpolating values into the query

```elixir
name_wildcard = "%donation%"
Repo.all(
  Query.from s in "surveys",
  where: like(s.name, ^name_wildcard),
  select: %{survey_name: s.name})
[%{survey_name: "Awesome event donation survey"}]
```

The generated SQL is logged at debug level:

```SQL
[debug] QUERY OK source="surveys" db=0.8ms
SELECT s0."name" FROM "surveys" AS s0 WHERE (s0."name" LIKE $1) ["%donation%"]
```

# Associations

Lets add some questions to the survey

`mix ecto.gen.migration add_survy_questions_table`

```elixir
defmodule Scout.Repo.Migrations.AddSurveyQuestionsTable do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :survey_id, references(:surveys, type: :uuid, on_delete: :delete_all)
      add :question, :text, null: false
      add :answer_format, :string, default: "text" # may also be :check, :select, :radio
      add :options, :jsonb
      timestamps()
    end

    create index(:questions, [:survey_id])
  end
end
```

Add some seed data.

```elixir
#priv/repo/seeds.exs
{2, [%{id: signup_survey_id}, %{id: donation_survey_id}]} = Repo.insert_all(
  ...,
  returning: [:id])

Repo.insert_all(
  "questions",
  [
    %{
      survey_id: signup_survey_id,
      display_index: 1,
      question: "T-Shirt size",
      answer_format: "select",
      options: ["S", "M", "L", "XL"],
      inserted_at: now,
      updated_at: now
    },
    %{
      survey_id: donation_survey_id,
      display_index: 1,
      question: "How would you like your funds to be allocated?",
      answer_format: "radio",
      options: ["Cancer ward", "Maternaty ward", "Psychiatric ward"],
      inserted_at: now,
      updated_at: now
    }
  ])
```

Now join surveys with questions:

```elixir
Repo.all(
  Query.from s in "surveys",
  join: q in "questions", on: s.id == q.survey_id,
  where: like(s.name, "%donation%"),
  select: %{index: q.display_index, text: q.question},
  order_by: [asc: q.survey_id, asc: q.display_index])

[%{index: 1, text: "How would you like your funds to be allocated?"}]
```

How do we load a Survey _and_ all of its questions?

# Schemas - Associations

Simple bulk-inserts and read-only reporting queries can be performed using ectos 'schema-less' queries as above.
However associations, updates and validations require the use of ecto schemas.

A schema is simply a struct with types given to each field, optionally mapped to a database table.

Lets create schemas for the Survey and Question tables.

```elixir
defmodule Scout.Survey do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "surveys" do
    field :owner_id, :binary_id
    field :name, :string
    field :state, :string
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    timestamps()

    has_many :questions, Scout.Question
  end
end
```

```elixir
defmodule Scout.Question do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id

  schema "questions" do
    belongs_to :survey, Scout.Survey
    field :display_index, :integer
    field :question, :string
    field :answer_format, :string
    field :options, {:array, :string}
    timestamps()
  end
end
```


And now query for donations with questions:

```elixir
Repo.all(Query.from s in Scout.Survey,
  where: like(s.name, "%donation%"),
  preload: :questions)
```
By default preloads are a second query:

```SQL
[debug] QUERY OK source="surveys" db=0.3ms
SELECT s0."id", s0."owner_id", s0."name", s0."state", s0."started_at", s0."finished_at", s0."inserted_at", s0."updated_at"
FROM "surveys" AS s0
WHERE (s0."name" LIKE '%donation%') []

[debug] QUERY OK source="questions" db=0.5ms
SELECT q0."id", q0."survey_id", q0."display_index", q0."question", q0."answer_format", q0."options", q0."inserted_at", q0."updated_at", q0."survey_id"
FROM "questions" AS q0
WHERE (q0."survey_id" = $1)
ORDER BY q0."survey_id" [<<220, 157, 250, 158, 126, 201, 76, 107, 177, 86, 84, 155, 188, 189, 170, 115>>]
```

Associations also simplify join queries:

```elixir
Repo.all(Query.from s in Scout.Survey,
  join: q in assoc(s, :questions),
  where: like(s.name, "%donation%") and q.answer_format == "radio",
  preload: [questions: q])
```

# Composable Queries

Queries can be broken down into composable parts for re-use and dynamic construction:

Add a `Scout.Survey.Query` module that can build a query from some params:

```elixir
defmodule Scout.Survey.Query do
  require Ecto.Query
  import Ecto.Query, only: [from: 2]

  def build(params) do
    Enum.reduce(params, Scout.Survey, fn
      {"owner", id}, query        -> query |> for_owner(id)
      {"name", pattern}, query    -> query |> name_like(pattern)
      {"state", state}, query     -> query |> in_state(state)
      {"started", "+"<>t}, query  -> query |> started_after(t |> DateTime.from_iso8601() |> elem(1))
      {"finished", "-"<>t}, query -> query |> finished_before(t |> DateTime.from_iso8601() |> elem(1))
    end)
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
```

This can then be used to build an Ecto query from some HTTP query params:

```elixir
params = %{
  "owner" => "b5c7cf2d-df82-42f8-a6ff-f93b4d2a39b7",
  "name" => "%donation%",
  "state" => "design",
  "finished" => "-2018-12-30T00:00:00Z",
  "started" => "+2017-01-01T00:01:03Z"
}
query = Scout.Survey.Query.build(params)

Ecto.Adapters.SQL.to_sql(:all, Scout.Repo, query)

{"SELECT s0.\"id\", s0.\"owner_id\", s0.\"name\", s0.\"state\", s0.\"started_at\", s0.\"finished_at\", s0.\"inserted_at\", s0.\"updated_at\" FROM \"surveys\" AS s0 WHERE (s0.\"finished_at\" < $1) AND (s0.\"name\" LIKE $2) AND (s0.\"owner_id\" = $3) AND (s0.\"started_at\" > $4) AND (s0.\"state\" = $5)",
 [{{2018, 12, 30}, {0, 0, 0, 0}}, "%donation%",
  <<181, 199, 207, 45, 223, 130, 66, 248, 166, 255, 249, 59, 77, 42, 57, 183>>,
  {{2017, 1, 1}, {0, 1, 3, 0}}, "design"]}
```


# Embedded Schemas and Validation

When a schema doesn't map to a database table, it can be declared as embedded.
This allows us to have the benefits of an explicitly typed struct even when not accessing the DB.

Lets add a `:create` action that will insert a new survey:

```elixir
defmodule Scout.Web.SurveyController do
  use Scout.Web, :controller
  alias Phoenix.controller
  alias Plug.Conn
  alias Scout.Core

  def create(conn, params) do
    with {:ok, survey} <- Core.create_survey(params) do
      conn
      |> Conn.put_status(201)
      |> Controller.json(Map.from_struct(survey))
    else
      {:error, errors} ->
        conn
        |> Conn.put_status(422)
        |> Controller.json(%{errors: errors})
    end
  end
end
```

With the business logic in a `Scout.Core` module:

```elixir
defmodule Scout.Core do
  alias Ecto.Changeset
  alias Scout.Repo
  alias Scout.Survey.{Create, Query}
  alias Scout.Util.ErrorHelpers

  def create_survey(params) do
    changeset = Create.changeset(params)
    case changeset do
      %{valid?: true} -> Create.run(Changeset.apply_changes(changeset))
      _ -> {:error, ErrorHelpers.changeset_errors(changeset)}
    end
  end
end
```

Scout.Survey.Create is a bit like a `FormObject` pattern:

 - Casts from plain maps to typed structs
 - Validates all required fields are present
 - Custom validation for survey question options.

```elixir
defmodule Scout.Survey.Create do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Survey.Create

  embedded_schema do
    field :owner_id, :string
    field :name, :string

    embeds_many :questions, Question, primary_key: false do
      field :question, :string
      field :answer_format, :string
      field :options, {:array, :string}
    end
  end

  def run(_cmd = %Create{}) do
    # TODO: map the command schema to a DB schema changeset and persist
    %Scout.Survey{}
  end

  def changeset(params) do
    %Create{}
    |> Changeset.cast(params, [:owner_id, :name])
    |> Changeset.validate_required([:owner_id, :name])
    |> Changeset.cast_embed(:questions, required: true, with: &question_changeset/2)
  end

  defp question_changeset(schema, params) do
    schema
    |> Changeset.cast(params, [:question, :answer_format, :options])
    |> Changeset.validate_required([:question, :answer_format])
    |> validate_options()
  end

  defp validate_options(cs = %Changeset{}) do
    case Changeset.get_field(cs, :answer_format) do
      "check" ->
        cs
        |> Changeset.validate_required(:options)
        |> Changeset.validate_length(:options, min: 1)
      fmt when fmt in ["select", "radio"] ->
        cs
        |> Changeset.validate_required(:options)
        |> Changeset.validate_length(:options, min: 2)
      _ -> cs
    end
  end
end
```

get_errors is a helper to deep traverse a changeset formatting error messages:

```elixir
def get_errors(changeset = %Changeset{}) do
  Changeset.traverse_errors(changeset, fn {msg, opts} ->
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end)
end
```

# Writing Changesets to the Database

Lets map the `Scout.Survey.Create` schema onto a Scout.Survey schema and changeset:

```elixir
def run(_cmd = %Create{}) do

end
```

# Transactions and Multi
