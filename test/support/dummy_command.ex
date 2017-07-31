defmodule Scout.Commands.DummyCommand do
  use Scout.Commands.Command

  cmd do
    attr :name, :string, [:required]
    attr :desc, :string, [:required, {:length, min: 2}]
    attr :color, :string, [{:custom, fn f, v -> validate_red(f, v) end}]
    attr :email, :string, [{:format, ~r/@/}]
  end

  def validate_red(_field, "red"), do: []
  def validate_red(field, _), do: [{field, "is not red"}]
end
