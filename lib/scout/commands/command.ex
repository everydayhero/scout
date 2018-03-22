defmodule Scout.Commands.Command do
  alias Ecto.Changeset
  alias Scout.Util.ValidationHelpers

  @moduledoc ~S"""
  Defines a Command.

  A Command is a module that defines a struct (via an embeded `Ecto.Schema`) and a `new/1` function that casts and validates params to build the struct. It will returns `{:ok, %__MODULE__{}}` on success, `{:error, %Ecto.Changeset{}}` otherwise.

  A command is a convenient way to define a Module that can take some user input, validate it, and return a schema that is ready to "run". Although Commands use an embeded `Ecto.Schema` under the hood they have nothing to do with databases, instead they are used to convey an intended action, usually from an external system or user.

  ## Examples

  Lets take a look at a contrived example at a command to update an email address for a user. The `run` function is completely optional and can be part of any Module, it is just there to illustrate a convenient use of a command.

      defmodule UpdateEmailAddress do
        use Scout.Commands.Command

        command do
          attr :user_id, :binary_id, required: true
          attr :updated_email, :string, format: ~r/@/
        end

        def run(_update_command = %__MODULE__{}) do
          # Update the data store.
          :ok
        end
      end

      iex> params = %{
      ...>   "user_id" => "447290e1-97b9-423b-bb76-07c6f3a4e41e",
      ...>   "updated_email" => "foo@bar.com"
      ...> }
      iex> {:ok, cmd} = UpdateEmailAddress.new(params)
      iex> cmd
      %UpdateEmailAddress{updated_email: "foo@bar.com", user_id: "447290e1-97b9-423b-bb76-07c6f3a4e41e"}
      iex> UpdateEmailAddress.run(cmd)
      :ok

  Any validation errors will result in `Ecto.Changeset` errors.

      iex> params = %{
      ...>   "updated_email" => "foo"
      ...> }
      iex> {:error, %Ecto.Changeset{errors: errors}} = UpdateEmailAddress.new(params)
      iex> errors
      [user_id: {"can't be blank", [validation: :required]},
      updated_email: {"has invalid format", [validation: :format]}]

  The supported validations are:
  * `required: boolean`, expands to `Ecto.Changeset.validate_required/3`
  * `format: regex`, expands to `Ecto.Changeset.validate_format/3`
  * `length: [min: number, max: number]`, expands to `Ecto.Changeset.validate_length/3`
  * `validate: function`, expands to `Ecto.Changeset.validate_change/3`

  Commands can be composed of command components, these compositions can be `many` or `one`. Lets take a look at a contrived example for many:

      defmodule Elixir.AddIngredients do
        use Scout.Commands.Command

        defmodule Ingredient do
          use Scout.Commands.Command

          @units ["tsp", "ml", "pinch", "g"]

          command_component do
            attr :name, :string, required: true
            attr :quantity, :decimal, required: true
            attr :unit, :string, validate: &validate_unit/2
          end

          def validate_unit(_field, unit) when unit in @units, do: []
          def validate_unit(field, _unit), do: [{field, "is not a known unit"}]
        end

        command do
          attr :recipe_id, :binary_id, required: true
          many :ingredients, Ingredient, required: true
        end
      end

      iex> params = %{
      ...>   "recipe_id" => "b78e6366-a30c-40fb-bf56-0bd9760938ee",
      ...>   "ingredients" => [%{
      ...>     "name" => "sugar",
      ...>     "quantity" => 3,
      ...>     "unit" => "tsp",
      ...>   }]
      ...> }
      iex> {:ok, command} = AddIngredients.new(params)
      iex> command
      %AddIngredients{ingredients: [%AddIngredients.Ingredient{name: "sugar", quantity: %Decimal{coef: 3, exp: 0, sign: 1}, unit: "tsp"}], recipe_id: "b78e6366-a30c-40fb-bf56-0bd9760938ee"}

  Any validation errors for command components will be the value of the `errors` key in the `Ecto.Changeset` that is the value of the component's key.

      iex> params = %{
      ...>   "recipe_id" => "b78e6366-a30c-40fb-bf56-0bd9760938ee",
      ...>   "ingredients" => [%{
      ...>     "name" => "sugar",
      ...>     "quantity" => 3,
      ...>     "unit" => "mounds",
      ...>   }]
      ...> }
      iex> {:error, %Ecto.Changeset{changes: %{ingredients: [%Ecto.Changeset{errors: errors}]}}} = AddIngredients.new(params)
      iex> errors
      [unit: {"is not a known unit", []}]

  If the command component is `required: true` leaving the property off of the input parameters will result in a validation error.

      iex> params = %{
      ...>   "recipe_id" => "b78e6366-a30c-40fb-bf56-0bd9760938ee",
      ...> }
      iex> {:error, %Ecto.Changeset{errors: errors}} = AddIngredients.new(params)
      iex> errors
      [ingredients: {"can't be blank", [validation: :required]}]

  Here is a similar example using `one`:

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

      iex> params = %{
      ...>   "user_id" => "b78e6366-a30c-40fb-bf56-0bd9760938ee",
      ...>   "name" => %{
      ...>     "first" => "A",
      ...>     "last" => "Test"
      ...>   }
      ...> }
      iex> {:error, %Ecto.Changeset{changes: %{name: %Ecto.Changeset{errors: errors}}}} = UpdateName.new(params)
      iex> errors
      [first: {"should be at least %{count} character(s)", [count: 2, validation: :length, min: 2]}]

  In addition to validating attributes it is also possible to validate a command as a whole, this can be helpful if a validation is based on more than one attribute.

      defmodule Elixir.UpdateNotificationSettings do
        use Scout.Commands.Command

        command do
          attr :email, :string
          attr :mobile, :string
          attr :notify_using, {:array, :string}, required: true

          validate &validate_notifications/1
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

      iex> params = %{
      ...>   "notify_using" => ["email"]
      ...> }
      iex> {:error, %Ecto.Changeset{errors: errors}} = UpdateNotificationSettings.new(params)
      iex> errors
      [email: {"can't be blank", [validation: :required]}]
  """

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
      nil,
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
