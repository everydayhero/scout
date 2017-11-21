defmodule AddIngredients do
  use Scout.Commands.Command

  defmodule Ingredient do
    use Scout.Commands.Command

    @units ["tsp", "ml", "pinch", "g"]

    command_component do
      attr(:name, :string, required: true)
      attr(:quantity, :decimal, required: true)
      attr(:unit, :string, validate: &validate_unit/2)
    end

    def validate_unit(_field, unit) when unit in @units, do: []
    def validate_unit(field, _unit), do: [{field, "is not a known unit"}]
  end

  command do
    attr(:recipe_id, :binary_id, required: true)
    many(:ingredients, Ingredient, required: true)
  end
end
