defmodule UpdateEmailAddress do
  use Scout.Commands.Command

  command do
    attr(:user_id, :binary_id, required: true)
    attr(:updated_email, :string, format: ~r/@/)
  end

  def run(_update_command = %__MODULE__{}) do
    # Update the data store
    :ok
  end
end
