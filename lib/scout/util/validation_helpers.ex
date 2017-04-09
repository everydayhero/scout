defmodule Scout.Util.ValidationHelpers do
  def validate_uuid(field, val) do
    case Ecto.UUID.cast(val) do
      :error -> [{field, "Is not a valid UUID"}]
      {:ok, _} -> []
    end
  end
end
