defmodule UpdateName do
  use Scout.Commands.Command

  defmodule Name do
    use Scout.Commands.Command

    command_component do
      attr :first, :string, required: true, length: [min: 2]
      attr :last, :string, required: true, length: [min: 2]
    end
  end

  command do
    attr :user_id, :binary_id, required: true
    one :name, Name, required: true
  end
end
