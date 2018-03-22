defmodule Scout.Question do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime, usec: true]
  @foreign_key_type :binary_id

  schema "questions" do
    belongs_to(:survey, Scout.Survey)
    field(:display_index, :integer)
    field(:question, :string)
    field(:answer_format, :string)
    field(:options, {:array, :string})
    timestamps()
  end
end
