defmodule Scout.Commands.Command.Test do
  use Scout.DataCase, async: true
  alias Scout.Commands.DummyCommand
  alias Scout.Commands.DummyChildCommand

  describe "declared command" do
    test "can be newed" do
      {:ok, dummy_command} = DummyCommand.new(
        %{
          name: "name",
          desc: "desc",
          email: "test@test.com",
          color: "red",
          children: []
        }
      )

      assert %DummyCommand{
        name: "name",
        desc: "desc",
        email: "test@test.com",
        color: "red",
        children: []
      } == dummy_command
    end

    test "can have children" do
      {:ok, dummy_command} = DummyCommand.new(
        %{
          name: "name",
          desc: "desc",
          email: "test@test.com",
          color: "red",
          children: [%{name: "child1"}]
        }
      )

      assert %DummyCommand{
        name: "name",
        desc: "desc",
        email: "test@test.com",
        color: "red",
        children: [%DummyChildCommand{name: "child1"}]
      } == dummy_command
    end

    test "validates children's properties" do
      {:error, %{changes: %{children: [%{errors: errors}]}}} = DummyCommand.new(
        %{
          name: "name",
          desc: "desc",
          email: "test@test.com",
          color: "red",
          children: [%{}]
        }
      )

      assert [
        name: {"can't be blank",
          [
            validation: :required
          ]
        },
      ] == errors
    end

    test "validates required" do
      {:error, %{errors: errors}} = DummyCommand.new(
        %{
          email: "test@test.com",
          color: "red",
          children: []
        }
      )

      assert [
        name: {"can't be blank",
          [
            validation: :required
          ]
        },
        desc: {"can't be blank",
          [
            validation: :required
          ]
        }
      ] == errors
    end

    test "validates length" do
      {:error, %{errors: errors}}  = DummyCommand.new(
        %{
          name: "name",
          desc: ".",
          email: "test@test.com",
          color: "red",
          children: []
        }
      )

      assert [
        desc: {
          "should be at least %{count} character(s)",
          [count: 2, validation: :length, min: 2]
        }
      ] == errors
    end

    test "validates format" do
      {:error, %{errors: errors}}  = DummyCommand.new(
        %{
          name: "name",
          desc: "desc",
          email: ".",
          color: "red",
          children: []
        }
      )

      assert [
        email: {
          "has invalid format",
          [validation: :format]
        }
      ] == errors
    end

    test "validates custom" do
      {:error, %{errors: errors}}  = DummyCommand.new(
        %{
          name: "name",
          desc: "desc",
          email: "test@test.com",
          color: "blue",
          children: []
        }
      )

      assert [
        color: { "is not red", [] }
      ] == errors
    end
  end
end
