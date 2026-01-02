defmodule TailwindMerge.Parsed do
  alias TailwindMerge.Parser

  defstruct [:class, :group, :modifiers, :important?]

  def new(class) do
    {modifiers, base_classname} =
      case Parser.modifiers(class) do
        {:ok, modifiers, base_classname, _, _, _} -> {modifiers, base_classname}
        error -> raise "Failed to parse #{class}: #{inspect(error)}"
      end

    normalized_classname = String.replace(base_classname, ~r/(^!|!$)/, "")
    important? = normalized_classname != base_classname

    group =
      case Parser.class(normalized_classname) do
        {:ok, [{:arbitrary_property, grouping}], "", _, _, _} -> grouping
        {:ok, [{grouping, _}], "", _, _, _} -> grouping
        _ -> normalized_classname
      end

    %__MODULE__{
      class: class,
      group: group,
      modifiers: sort_modifiers(modifiers),
      important?: important?
    }
  end

  defp sort_modifiers(modifiers) do
    modifiers
    |> Enum.reduce(
      [[]],
      fn
        {:regular_modifier, modifier}, [current_segment | rest] ->
          [[modifier] ++ current_segment | rest]

        {:arbitrary_modifier, modifier}, [current_segment | rest] ->
          [[modifier] | [Enum.sort(current_segment) ++ rest]]
      end
    )
    |> Enum.flat_map(&Enum.sort/1)
    |> Enum.reverse()
  end
end
