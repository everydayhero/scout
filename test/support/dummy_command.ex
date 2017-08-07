defmodule Scout.Commands.DummyCommand do
  use Scout.Commands.Command

  command do
    attr :name, :string, required: true
    attr :desc, :string, required: true, length: [min: 2]
    attr :color, :string, validate: fn f, v -> validate_red(f, v) end
    attr :email, :string, format: ~r/@/
  end

  def validate_red(_field, "red"), do: []
  def validate_red(field, _), do: [{field, "is not red"}]
end
