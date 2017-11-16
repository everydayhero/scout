# Scout

Protoss unit highly skilled at conducting Surveys.

This repo is used for experimentation and as a training tool for elixir development. Also seen at the [Brisbane Elixir Meetup](https://www.meetup.com/brisbane-elixir/)

## Build instructions

Prerequisites: Docker (tested with Docker for Mac)

Setup pre-commit format hook

```
./bin/setup
```

Fetch dependencies:

```
./bin/deps
```

Compile source code:

```
./bin/compile
```

Run unit tests:

```
./bin/test
```

Run database migrations:

```
./bin/dbmigrate
```

Start iex console:

```
./bin/iex
```

Start a local server, listening on local port 4000:

```
./bin/dev
```

Build a docker image:

```
./bin/release
```

Run the release docker image:

```
./bin/scout
```

Run a mix task:

```
./bin/mix test --trace
```


# Learning Objectives

Cover the 5 core aspects of the Ecto library:

## Migrations

Add tables, indexes.
Show how to run direct SQL or fragments.

## Repo

Is the interface to the DB connection.
Can perform bulk operations without the need for a schema definition.
Provides transaction/rollback functionality.

## Schema

Defines typed structures.
Can be optionally mapped to database tables, but are generally useful anywhere you want typed fields.

## Query

Ecto separates query construction from execution.
This allows for highly composable queries.
Use a `reduce` function to convert dynamic query params into a query.

## Changeset

Mechanism for validating inputs, and changes to structs.
Logical change tracking for immutable data structures.
Can be composed into `Multi` for transactional semantics.


# Getting Started

```
mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez
mix phx.new scout --binary-id --no-html --no-brunch
cd scout
mix ecto.create
mix phoenix.server
```


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
  password: "password",
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

Add a `Scout.SurveyQuery` module that can build a query from some params:

```elixir
defmodule Scout.SurveyQuery do
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
query = Scout.SurveyQuery.build(params)

Ecto.Adapters.SQL.to_sql(:all, Scout.Repo, query)

{
  """
  SELECT s0."id", s0."owner_id", s0."name", s0."state", s0."started_at", s0."finished_at", s0."inserted_at", s0."updated_at"
  FROM "surveys" AS s0
  WHERE (s0."finished_at" < $1) AND (s0."name" LIKE $2) AND (s0."owner_id" = $3) AND (s0."started_at" > $4) AND (s0."state" = $5)
  """,
  [{{2018, 12, 30}, {0, 0, 0, 0}}, "%donation%",
  <<181, 199, 207, 45, 223, 130, 66, 248, 166, 255, 249, 59, 77, 42, 57, 183>>,
  {{2017, 1, 1}, {0, 1, 3, 0}}, "design"]
}
```


# Embedded Schemas and Validation

When a schema doesn't map to a database table, it can be declared as embedded.
This allows us to have the benefits of an explicitly typed struct even when not accessing the DB.

Lets add a `:create` action that will insert a new survey:

```elixir
defmodule Scout.Web.SurveyController do
  use Scout.Web, :controller
  alias Phoenix.Controller
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
  alias Scout.{Repo, Survey, SurveyQuery}
  alias Scout.Commands.{CreateSurvey, RenameSurvey}
  alias Scout.Util.ErrorHelpers

  @doc """
  Create a survey given a string-keyed map of params

  Example Params:

      %{
        "name" => "my survey",
        "owner_id" => "234-234235-23123",
        "questions" => [
          %{"question" => "Marvel or DC?", "answer_format" => "radio", "options" => ["Marvel", "DC"]},
          %{"question" => "Daytime phone number", "answer_format" => "text"}
        ]
      }

  Returns {:error, errors} on failure, or {:ok, survey} on success.
  """
  def create_survey(params) do
    with {:ok, cmd} <- CreateSurvey.new(params) do
      cmd
      |> CreateSurvey.run()
      |> Repo.multi_transaction()
    else
      {:error, changeset} -> {:error, ErrorHelpers.changeset_errors(changeset)}
    end
  end
end
```

Scout.Commands.CreateSurvey is responsible for:

 - Casts from plain maps to typed structs
 - Validates all required fields are present
 - Custom validation for survey question options.

```elixir
defmodule Scout.Commands.CreateSurvey do
  @moduledoc """
  Defines the schema and validations for the parameters required to create a new survey.
  Note that this doesn't define the database schema, only the structure of the external params payload.
  """

  use Ecto.Schema

  alias Ecto.{Changeset, Multi}
  alias Scout.Commands.{CreateSurvey, EmbeddedQuestion}
  alias Scout.Util.ValidationHelpers
  alias Scout.Survey

  @primary_key false
  embedded_schema do
    field :owner_id, :string
    field :name, :string
    embeds_many :questions, EmbeddedQuestion
  end

  @doc """
  Create a new CreateSurvey struct from string-keyed map of params
  If validations fails, result is `{:error, %Changeset{}}`, otherwise returns {:ok, %CreateSurvey{}}
  """
  def new(params) do
    changeset = validate(params)
    if changeset.valid? do
      {:ok, Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end

  defp validate(params) do
    %CreateSurvey{}
    |> Changeset.cast(params, [:owner_id, :name])
    |> Changeset.validate_required([:owner_id, :name])
    |> Changeset.validate_change(:owner_id, &ValidationHelpers.validate_uuid/2)
    |> Changeset.cast_embed(:questions, required: true, with: &EmbeddedQuestion.validate_question/2)
  end

  @doc """
  Runs a CreateSurvey command

  Returns an Ecto.Multi representing the operation/s that must happen to create a new Survey.
  The multi should be run by the callng code using Repo.transaction or merged into a larger Multi as needed.
  """
  def run(cmd = %CreateSurvey{}) do
    Multi.new()
    |> Multi.insert(:survey, Survey.insert_changeset(cmd))
  end
end
```

```elixir
defmodule Scout.Commands.EmbeddedQuestion do
  @moduledoc """
  Defines the schema and validations for a survey question that may be embedded within another command.
  """

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :question, :string
    field :answer_format, :string
    field :options, {:array, :string}
  end

  @doc """
  Validation function that may be used in a call to Changeset.cast_assoc, or Changeset.cast_embed
  """
  def validate_question(schema, params) do
    schema
    |> Changeset.cast(params, [:question, :answer_format, :options])
    |> Changeset.validate_required([:question, :answer_format])
    |> validate_options()
  end

  @doc """
  Custom validation function for the `options` key in a question params map.

  For checkbox questions, there must be at least one options
  For Radio/Select questions, there must be at least two options
  Otherwise (free text), no options validation applies
  """
  def validate_options(cs = %Changeset{}) do
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

Ecto will throw an exception if unable to convert a string to a UUID, so use a custom validator to catch the problem early.

```elixir
defmodule Scout.Util.ValidationHelpers do
  def validate_uuid(field, val) do
    case Ecto.UUID.cast(val) do
      :error -> [{field, "Is not a valid UUID"}]
      {:ok, _} -> []
    end
  end
end
```

`ErrorHelpers.changeset_errors` is a helper to deep traverse a changeset formatting error messages:

```elixir
def changeset_errors(changeset = %Changeset{}) do
  Changeset.traverse_errors(changeset, fn {msg, opts} ->
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end)
end
```

Now we can create some surveys in iex

```elixir
iex(1)> Scout.Core.create_survey(%{})
{:error,
 %{name: ["can't be blank"], owner_id: ["can't be blank"],
   questions: ["can't be blank"]}}

iex(9)> Scout.Core.create_survey(
  %{
    "name" => "My cool survey",
    "owner_id" => Ecto.UUID.generate(),
    "questions" => [%{"question" => "Marvel or DC", "answer_format" => "radio", "options" => ["Marvel", "DC"]}]
  })

[debug] QUERY OK db=0.2ms
begin []
[debug] QUERY OK db=2.0ms
INSERT INTO "surveys" ("name","owner_id","state","inserted_at","updated_at","id") VALUES ($1,$2,$3,$4,$5,$6) ["My cool survey", <<140, 93, 2, 162, 25, 243, 75, 173, 182, 66, 45, 76, 60, 78, 8, 32>>, "design", {{2017, 4, 9}, {12, 23, 27, 641313}}, {{2017, 4, 9}, {12, 23, 27, 644702}}, <<68, 111, 125, 40, 156, 78, 77, 69, 142, 227, 171, 75, 63, 111, 230, 43>>]
[debug] QUERY OK db=6.4ms
INSERT INTO "questions" ("answer_format","display_index","options","question","survey_id","inserted_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING "id" ["radio", 0, ["Marvel", "DC"], "Marvel or DC", <<68, 111, 125, 40, 156, 78, 77, 69, 142, 227, 171, 75, 63, 111, 230, 43>>, {{2017, 4, 9}, {12, 23, 27, 653650}}, {{2017, 4, 9}, {12, 23, 27, 653656}}]
[debug] QUERY OK db=2.1ms
commit []

{:ok,
%Scout.Survey{__meta__: #Ecto.Schema.Metadata<:loaded, "surveys">,
 id: "446f7d28-9c4e-4d45-8ee3-ab4b3f6fe62b",
 owner_id: "8c5d02a2-19f3-4bad-b642-2d4c3c4e0820",
 name: "My cool survey",
 started_at: nil,
 finished_at: nil,
 state: "design",
 questions: [%Scout.Question{__meta__: #Ecto.Schema.Metadata<:loaded, "questions">,
   id: 11,
   survey_id: "446f7d28-9c4e-4d45-8ee3-ab4b3f6fe62b",
   display_index: 0,
   answer_format: "radio",
   options: ["Marvel", "DC"], question: "Marvel or DC",
   survey: #Ecto.Association.NotLoaded<association :survey is not loaded>,
   inserted_at: %DateTime{...},
   updated_at: %DateTime{...}}],
 inserted_at: %DateTime{...},
 updated_at: %DateTime{...}}
}
```

# Writing Changesets to the Database

Lets map the `Scout.Commands.CreateSurvey` schema onto a Scout.Survey schema and changeset:
Note that we're using `change` and `put_assoc` instead of `cast` and `cast_assoc` because the data validation has already happened.

```elixir
@doc """
Given a validated Survey.Create struct, creates a changeset that will insert a new Survey in the database.
Note that the unique constraint on `name` may still cause a failure in Repo.insert.
"""
def insert_changeset(cmd = %CreateSurvey{}) do
  survey_params = %{
    owner_id: cmd.owner_id,
    name: cmd.name,
    state: "design"
  }

  questions =
    for {val, idx} <- Enum.with_index(cmd.questions) do
      val
      |> Map.from_struct()
      |> Map.put(:display_index, idx)
    end

  %Scout.Survey{}
  |> Changeset.change(survey_params)
  |> Changeset.unique_constraint(:name)
  |> Changeset.put_assoc(:questions, questions)
end
```

# Updates and Transactions

Inserts a pretty simple, there's not really any chance of concurrency errors except for unique constraints or check constraints.
When it comes to updates you probably want to control the transaction boundary.

```elixir
@doc """
Renames a survey given string-keyed map of params.

Params:

 - "id"   : The survey id
 - "name" : The new name of the survey

Returns {:ok, %{survey: %Scout.Survey{}}} on success, {:error, errors} on failure.
"""
def rename_survey(params) do
  with {:ok, cmd} <- RenameSurvey.new(params) do
    RenameSurvey.run(cmd)
  else
    {:error, changeset} -> {:error, ErrorHelpers.changeset_errors(changeset)}
  end
end
```

The `RenameSurvey` command is quite simple:

```elixir
defmodule Scout.Commands.RenameSurvey do
  @moduledoc """
  Defines the schema and validations for a RenameSurvey command.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias Scout.Commands.RenameSurvey
  alias Scout.Util.{ErrorHelpers, ValidationHelpers}
  alias Scout.{Repo, Survey, SurveyQuery}

  @primary_key false
  embedded_schema do
    field :id, :binary_id
    field :name, :string
  end

  @doc """
  Create a new RenameSurvey struct from string-keyed map of params

  If validations fails, result is `{:error, errors}`, otherwise returns {:ok, struct}
   - "id" is required and must b a uuid
   - "name" is required

  returns {:error, errors} on validation failure, {:ok, struct} otherwise.
  """
  def new(params) do
    with cs = %{valid?: true} <- validate(params) do
      {:ok, Changeset.apply_changes(cs)}
    else
      changeset -> {:error, changeset}
    end
  end

  defp validate(params) do
    %RenameSurvey{}
    |> Changeset.cast(params, [:id, :name])
    |> Changeset.validate_required([:id, :name])
    |> Changeset.validate_change(:id, &ValidationHelpers.validate_uuid/2)
  end

  @doc """
  Runs a RenameSurvey command in a transaction.

  Returns {:ok, %{survey: %Survey{}}} on sucess, {:error, errors} otherwise.

  This implementation demonstrates the usage of Repo.transaction and Repo.rollback

  Unlike the `CreateSurvey` and `AddSurveyResponse` commands, this command module interacts with
  the repo directly so that it can manage the transaction scope.
  """
  def run(cmd = %RenameSurvey{}) do
    Repo.transaction fn ->
      with survey = %Survey{} <- Repo.one(SurveyQuery.for_update(id: cmd.id)),
           changeset <- Survey.rename_changeset(survey, cmd),
           {:ok, survey} <- Repo.update(changeset) do
        %{survey: survey}
      else
        {:error, changeset} -> Repo.rollback(ErrorHelpers.changeset_errors(changeset))
      end
    end
  end
end
```

Note that on the happy path `survey` isn't wrapped in an `{:ok, survey}` tuple, and on the error path we use `rollback` with the error list.  This is because `transaction` does this automatically.

Gotcha! The only way to propagate error info out of a transaction is to call `rollback` explicitly.
Without `Repo.rollback` the error is always `{:error, :rollback}` which is not very informative.

SurveyQuery.for_update uses the `Ecto.Query.from` `lock` keyword:

```elixir
def for_update(id: id) do
  from Survey, where: [id: ^id], lock: "FOR UPDATE", preload: :questions
end
```

`Survey.rename_changeset` is also quite simple.
Note the pattern matching ensures the `id` matches in both structs.

```elixir
@doc """
Given a validated UpdateSurvey struct, creates a changeset that will rename the survey
"""
def rename_changeset(survey = %Survey{id: id}, %RenameSurvey{id: id, name: name}) do
  survey
  |> Changeset.change(name: name)
  |> Changeset.unique_constraint(:name)
end
```

```elixir
iex(1)> Scout.Core.rename_survey(%{"id" => "446f7d28-9c4e-4d45-8ee3-ab4b3f6fe62b", "name" => "i like this better"})
[debug] QUERY OK db=0.3ms
begin []

[debug] QUERY OK source="surveys" db=2.9ms decode=1.8ms
SELECT s0."id", s0."owner_id", s0."name", s0."state", s0."started_at", s0."finished_at", s0."inserted_at", s0."updated_at"
FROM "surveys" AS s0
WHERE (s0."id" = $1)
FOR UPDATE
[<<68, 111, 125, 40, 156, 78, 77, 69, 142, 227, 171, 75, 63, 111, 230, 43>>]

[debug] QUERY OK source="questions" db=4.7ms
SELECT q0."id", q0."survey_id", q0."display_index", q0."question", q0."answer_format", q0."options", q0."inserted_at", q0."updated_at", q0."survey_id"
FROM "questions" AS q0
WHERE (q0."survey_id" = $1)
ORDER BY q0."survey_id"
[<<68, 111, 125, 40, 156, 78, 77, 69, 142, 227, 171, 75, 63, 111, 230, 43>>]

[debug] QUERY OK db=0.6ms
UPDATE "surveys"
SET "name" = $1, "updated_at" = $2 WHERE "id" = $3
["i like this better", {{2017, 4, 9}, {12, 30, 26, 345155}}, <<68, 111, 125, 40, 156, 78, 77, 69, 142, 227, 171, 75, 63, 111, 230, 43>>]

[debug] QUERY OK db=2.2ms
commit []
```

# Ecto Multi

Scoped transactions can work well, but there are some tradeoffs.
A connection is taken from the pool for the duration of the transaction, you need to take care not to do any blocking API calls while the transaction is open.

Ecto provides an alternative for composable updates similar to composable queries, called `Multi`.

Multi is a collection of named changesets that will be executed in a transaction.
The trick is that you can build the Multi from smaller changesets, then finally submit it to the Repo.

Lets add survey responses to the database:

```elixir
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
```

And a counter cache for responses on the `surveys` table:

```elixir
defmodule Scout.Repo.Migrations.AddSurveyResponseCountField do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :response_count, :integer, null: false, default: 0
    end
  end
end
```

Add the new relation and counter to the `Survey` schema:

```elixir
schema "surveys" do
  field :owner_id, :binary_id
  field :name, :string
  field :state, :string
  field :started_at, :utc_datetime
  field :finished_at, :utc_datetime
  field :response_count, :integer
  timestamps()

  has_many :questions, Scout.Question
  has_many :responses, Scout.Response
end
```

Define the responses schema:

```elixir
schema "responses" do
  belongs_to :survey, Scout.Survey
  field :respondant_email, :string
  field :answers, {:array, :string}
  timestamps()
end
```

Add a command to define the request parameters:

```elixir
defmodule Scout.Commands.AddSurveyResponse do
use Ecto.Schema
alias Ecto.Changeset
alias Scout.Util.ValidationHelpers

@primary_key false
embedded_schema do
  field :survey_id, :binary_id
  field :respondant_email, :string
  field :answers, {:array, :string}
end

def new(params) do
  with cs = %{valid?: true} <- validate(params) do
    {:ok, Changeset.apply_changes(cs)}
  else
    changeset -> {:error, changeset}
  end
end

defp validate(params) do
  %__MODULE__{}
  |> Changeset.cast(params, [:survey_id, :respondant_email, :answers])
  |> Changeset.validate_required([:survey_id, :respondant_email, :answers])
  |> Changeset.validate_change(:survey_id, &ValidationHelpers.validate_uuid/2)
  |> Changeset.validate_format(:respondant_email, ~r/@/)
end
```

Add a new changeset function in the survey module to increment the response counter:

```elixir
def increment_response_count_changeset(
    survey = %Survey{id: id, response_count: count, state: state},
    %AddSurveyResponse{survey_id: id}) do

  survey
  |> Changeset.change(response_count: count+1)
  |> validate_survey_running(state)
end

defp validate_survey_running(changeset, "running"), do: changeset
defp validate_survey_running(changeset, _) do
  Changeset.add_error(changeset, :state, "Survey is not running")
end
```

Add a changeset function in the `Response` module to insert a new response:

```elixir
def insert_changeset(%Survey{id: id}, cmd = %AddSurveyResponse{survey_id: id}) do
  response_params = Map.take(cmd, [:survey_id, :respondant_email, :answers])

  index_name = :responses_survey_id_respondant_email_index

  %__MODULE__{}
  |> Changeset.change(response_params)
  |> Changeset.unique_constraint(:respondant_email, name: index_name)
end
```

And tie is all together with a new function in core:

```elixir
def add_survey_response(params) do
  with {:ok, cmd} <- AddSurveyResponse.new(params),
       {:ok, survey} <- find_survey_by_id(cmd.survey_id) do
    Multi.new()
    |> Multi.insert(:response, Response.insert_changeset(survey, cmd))
    |> Multi.update(:survey, Survey.increment_response_count_changeset(survey, cmd))
    |> run_multi()
  else
    {:error, changeset = %Changeset{}} -> {:error, ErrorHelpers.changeset_errors(changeset)}
    {:error, errors} -> {:error, errors}
  end
end
```

`find_survey_by_id` is a helper that wraps a call to `Repo.get` in an error tuple:
```elixir
def find_survey_by_id(id) do
  case Repo.get(Survey, id) do
    nil -> {:error, "Survey not found"}
    survey -> {:ok, survey}
  end
end
```

`run_multi` is a local helper to execute the `Multi` and convert any errors to the usual {:error, errors} format:

```elixir
defp run_multi(multi = %Multi{}) do
  case Repo.transaction(multi) do
    {:ok, results} -> {:ok, results}
    {:error, operation, changeset, _changes} ->
      {:error, %{operation => ErrorHelpers.changeset_errors(changeset)}}
  end
end
```
