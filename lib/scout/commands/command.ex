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

  defp attribute_visitor({:one, meta, params = [_name, _command_type]}, acc) do
    attribute_visitor({:one, meta, params ++ [[required: false]]}, acc)
  end
  defp attribute_visitor(
    {:one, _meta, [name, command_type, [required: required]]},
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
      embeds_one unquote(name), unquote(command_type)
    end

    {
      field_ast,
      [field_names: field_names, validation_asts: [validation_func_ast | validation_funcs]]
    }
  end
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
      quote do end,
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
  defp attribute_visitor({:__block__, meta, fields}, accumulator) do
    fields = Enum.filter(fields, &!is_nil(&1))
    {{:__block__, meta, fields}, accumulator}
  end
  defp attribute_visitor(node, accumulator) do
    {node, accumulator}
  end

  defp ecto_to_typespec(type) do
    case type do
      :id -> quote do integer end
      :binary_id -> quote do String.t end
      :integer -> quote do integer end
      :float -> quote do float end
      :boolean -> quote do boolean end
      :string -> quote do String.t end
      :binary -> quote do binary end
      {:array, t} -> quote do [unquote(ecto_to_typespec(t))] end
      :map -> quote do %{} end
      {:map, _} -> quote do %{} end
      :decimal -> quote do Decimal.t end
      :date -> quote do Date.t end
      :time -> quote do Time.t end
      :naive_datetime -> quote do NaiveDateTime.t end
      :utc_datetime -> quote do DateTime.t end
    end
  end

  defp build_type_ast(fields_ast = {:__block__, _, _}, module) do
    Macro.postwalk(fields_ast, fn
      {:field, _, [name, type | _rest]} ->  quote do {unquote(name),  unquote(ecto_to_typespec(type))} end
      {:embeds_one, _, [name, type | _rest]} -> quote do {unquote(name), unquote(type).t} end
      {:embeds_many, _, [name, type | _rest]} -> quote do {unquote(name), [unquote(type).t]} end
      {:__block__, meta, args} -> {:%, [], [module, {:%{}, meta, args}]}
      node -> node
    end)
  end
  defp build_type_ast(field_ast, module) do
    build_type_ast({:__block__, [], [field_ast]}, module)
  end

  defmacro command_component(do: attributes) do
    {
      fields_ast,
      [field_names: field_names, validation_asts: validation_asts]
    } = Macro.postwalk(
      attributes,
      [field_names: [], validation_asts: []],
      &attribute_visitor/2
    )

    type_ast = build_type_ast(fields_ast, __CALLER__.module)

    quote do
      @type t :: unquote(type_ast)
      @primary_key false
      embedded_schema do
        unquote(fields_ast)
      end

      @spec validate(Changeset.t, Enumerable.t) :: Changeset.t
      def validate(changeset, params) do
        changeset
        |> Changeset.cast(Map.new(params), unquote(field_names))
        |> ValidationHelpers.validate_all(unquote(validation_asts))
      end

    end
  end

  defmacro command(do: attributes) do
    {
      fields_ast,
      [field_names: field_names, validation_asts: validation_asts]
    } = Macro.postwalk(
      attributes,
      [field_names: [], validation_asts: []],
      &attribute_visitor/2
    )

    type_ast = build_type_ast(fields_ast, __CALLER__.module)

    quote do
      @type t :: unquote(type_ast)
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
      defp validate(params) do
        %__MODULE__{}
        |> Changeset.cast(Map.new(params), unquote(field_names))
        |> ValidationHelpers.validate_all(unquote(validation_asts))
      end
    end
  end
end
