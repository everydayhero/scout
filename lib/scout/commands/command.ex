defmodule Scout.Commands.Command do
  alias Ecto.Changeset
  alias Scout.Util.ValidationHelpers

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import unquote(__MODULE__)
      alias Ecto.{Changeset, Multi}
    end
  end

  defp validation_visitor(node = {:validate, args}, validators) do
    validation_ast = quote do
      custom_validation_func = unquote(args)
      fn
        (changeset, field) -> Changeset.validate_change(changeset, field, custom_validation_func)
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = {:format, args}, validators) do
    validation_ast = quote do
      fn
        (changeset, field) -> Changeset.validate_format(changeset, field, unquote(args))
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = {:length, args}, validators) do
    validation_ast = quote do
      fn
        (changeset, field) -> Changeset.validate_length(changeset, field, unquote(args))
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = {:required, true}, validators) do
    validation_ast = quote do
      fn
        (changeset, field) -> Changeset.validate_required(changeset, field)
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node, validators), do: {node, validators}

  defp attribute_visitor({:attr, _meta, [name, type, declared_validations]}, {field_names, validation_funcs}) do
    {_ast, validators_for_field} = Macro.postwalk(declared_validations, [], &validation_visitor/2)

    validation_func_ast = quote do
      fn changeset ->
        Enum.reduce(
          unquote(validators_for_field),
          changeset,
          fn validator, changeset ->
            validator.(changeset, unquote(name))
          end
        )
      end
    end
    field_ast = quote do
      field unquote(name), unquote(type)
    end

    {field_ast, {[name | field_names], [validation_func_ast | validation_funcs]}}
  end
  defp attribute_visitor(node, validation_funcs), do: {node, validation_funcs}

  defmacro command(do: attributes) do
    {
      fields_ast,
      {field_names, validation_asts}
    } = Macro.postwalk(attributes, {[], []}, &attribute_visitor/2)

    quote do
      @primary_key false
      embedded_schema do
        unquote(fields_ast)
      end

      def new(params) do
        with changeset = %{valid?: true} <- validate(params) do
          {:ok, Changeset.apply_changes(changeset)}
        else
          changeset -> {:error, changeset}
        end
      end

      defp validate(params) do
        %__MODULE__{}
        |> Changeset.cast(Map.new(params), unquote(field_names))
        |> ValidationHelpers.validate_all(unquote(validation_asts))
      end
    end
  end
end
