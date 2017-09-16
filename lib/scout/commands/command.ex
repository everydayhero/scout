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
  defp validation_visitor(node, accumulator), do: {node, accumulator}

  defp attribute_visitor({:many, meta, params = [_name, _command_type]}, acc) do
    attribute_visitor({:many, meta, params ++ [[required: false]]}, acc)
  end
  defp attribute_visitor(
    {:many, _meta, [name, command_type, [required: required]]},
    [field_names: field_names, validation_asts: validation_funcs]
  ) do
    validation_func_ast = quote do
      fn
        (changeset) ->
          Changeset.cast_embed(
            changeset,
            unquote(name),
            required: unquote(required),
            with: &unquote(command_type).validate/2
          )
      end
    end

    field_ast = quote do
      embeds_many unquote(name), unquote(command_type)
    end

    {
      field_ast,
      [field_names: field_names, validation_asts: [validation_func_ast | validation_funcs]]
    }
  end
  defp attribute_visitor(
    {:validate, _meta, [changeset_validation_func_ast]},
    [field_names: field_names, validation_asts: validation_funcs]
  ) do
    {
      quote do {} end,
      [field_names: field_names, validation_asts: [changeset_validation_func_ast | validation_funcs]]
    }
  end
  defp attribute_visitor(
    {:attr, meta, [name, type]},
    acc
  ) do
    attribute_visitor({:attr, meta, [name, type, []]}, acc)
  end
  defp attribute_visitor(
    {:attr, _meta, [name, type, declared_validations]},
    [field_names: field_names, validation_asts: validation_funcs]
  ) do
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

    {
      field_ast,
      [field_names: [name | field_names], validation_asts: [validation_func_ast | validation_funcs]]
    }
  end
  defp attribute_visitor(node, accumulator), do: {node, accumulator}

  defmacro command(do: attributes) do
    {
      fields_ast,
      [field_names: field_names, validation_asts: validation_asts]
    } = Macro.postwalk(
      attributes,
      [field_names: [], validation_asts: []],
      &attribute_visitor/2
    )

    quote do
      @type t :: %__MODULE__{}
      @primary_key false
      embedded_schema do
        unquote(fields_ast)
      end

      @spec new(Enumerable.t) :: {:ok, t} | {:error, Changeset.t}
      def new(params) do
        with changeset = %{valid?: true} <- validate(params) do
          {:ok, Changeset.apply_changes(changeset)}
        else
          changeset -> {:error, changeset}
        end
      end

      @spec validate(Enumerable.t) :: Changeset.t
      def validate(changeset \\ %__MODULE__{}, params) do
        changeset
        |> Changeset.cast(Map.new(params), unquote(field_names))
        |> ValidationHelpers.validate_all(unquote(validation_asts))
      end
    end
  end
end
