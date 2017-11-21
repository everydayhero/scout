defmodule Scout.Repo do
  use Ecto.Repo, otp_app: :scout

  alias Scout.Util.ErrorHelpers

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  def multi_transaction(multi = %Ecto.Multi{}) do
    case transaction(multi) do
      {:ok, result} -> {:ok, result}
      {:error, operation, changeset, _changes} ->
        {:error, %{operation => ErrorHelpers.changeset_errors(changeset)}}
    end
  end
end
