defmodule Scout.Commands.Command do
  alias Ecto.Changeset

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import unquote(__MODULE__)
      alias Ecto.{Changeset, Multi}
    end
  end

  defp validation_visitor(node = {:custom, args}, validators) do
    validation_ast = quote do
      custom_validation_func = unquote(args)
      fn
        (changeset, prop) -> Changeset.validate_change(changeset, prop, custom_validation_func)
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = {:format, args}, validators) do
    validation_ast = quote do
      fn
        (changeset, prop) -> Changeset.validate_format(changeset, prop, unquote(args))
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = {:length, args}, validators) do
    validation_ast = quote do
      fn
        (changeset, prop) -> Changeset.validate_length(changeset, prop, unquote(args))
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node = :required, validators) do
    validation_ast = quote do
      fn
        (changeset, prop) -> Changeset.validate_required(changeset, prop)
      end
    end

    {node, [validation_ast | validators]}
  end
  defp validation_visitor(node, validators), do: {node, validators}

  defp attribute_visitor({:attr, _meta, [name, type, declared_validations]}, {field_names, validation_funcs}) do
    {_ast, validators_for_prop} = Macro.postwalk(declared_validations, [], &validation_visitor/2)

    validation_func_ast = quote do
      fn changeset ->
        Enum.reduce(
          unquote(validators_for_prop),
          changeset,
          fn vfp, cs ->
            vfp.(cs, unquote(name))
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

  defmacro cmd(do: attributes) do
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
        with cs = %{valid?: true} <- validate(params) do
          {:ok, Changeset.apply_changes(cs)}
        else
          changeset -> {:error, changeset}
        end
      end

      defp validate(params) do
        %__MODULE__{}
        |> Changeset.cast(params, unquote(field_names))
        |> Scout.Util.ValidationHelpers.validate_all(unquote(validation_asts))
      end
    end
  end
end
