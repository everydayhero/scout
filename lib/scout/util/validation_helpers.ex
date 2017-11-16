defmodule Scout.Util.ValidationHelpers do
  def validate_uuid(field, val) do
    case Ecto.UUID.cast(val) do
      :error -> [{field, "Is not a valid UUID"}]
      {:ok, _} -> []
    end
  end

  def validate_all(changeset, validation_funcs) when is_list(validation_funcs) do
    Enum.reduce(validation_funcs, changeset, fn validator, cs -> validator.(cs) end)
  end
end
