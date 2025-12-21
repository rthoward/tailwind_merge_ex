defmodule TailwindMerge.Parsed do
  alias TailwindMerge.Parser

  defstruct [:class, :group, :modifiers, :important?]

  def new(class) do
    normalized_class = String.replace(class, ~r/(^!|!$)/, "")
    important? = normalized_class != class

    {normalized_class, modifiers} =
      normalized_class
      |> String.split(":")
      |> Enum.reverse()
      |> case do
        [class] -> {class, []}
        [class | modifiers] -> {class, modifiers}
      end

    group =
      case Parser.class(normalized_class) do
        {:ok, [{grouping, _}], _, _, _, _} -> grouping
        _ -> normalized_class
      end

    modifiers = Enum.join(modifiers, ":")

    %__MODULE__{
      class: class,
      group: group,
      modifiers: modifiers,
      important?: important?
    }
  end

  def key(parsed), do: {parsed.modifiers, parsed.important?, parsed.group}
end
