defmodule UpdateNotificationSettings do
  use Scout.Commands.Command

  command do
    attr(:email, :string)
    attr(:mobile, :string)
    attr(:notify_using, {:array, :string}, required: true)

    validate(&validate_notifications/1)
  end

  defp validate_notifications(cs = %Changeset{}) do
    notify_using = Changeset.get_field(cs, :notify_using)
    validate_notifications(cs, notify_using)
  end

  defp validate_notifications(cs = %Changeset{}, ["sms" | tail]) do
    validate_notifications(Changeset.validate_required(cs, [:mobile]), tail)
  end

  defp validate_notifications(cs = %Changeset{}, ["email" | tail]) do
    validate_notifications(Changeset.validate_required(cs, [:email]), tail)
  end

  defp validate_notifications(cs = %Changeset{}, []), do: cs
end
