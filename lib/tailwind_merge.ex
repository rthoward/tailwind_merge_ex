defmodule TailwindMerge do
  @moduledoc """
  Documentation for `TailwindMerge`.
  """

  alias TailwindMerge.Parser

  @doc """
  Merge Tailwind CSS classes.

  ## Examples
  """
  def tw(classes) do
    classes
    |> flatten()
    |> merge()
    |> join()
  end

  defp merge(classes) do
    classes
    |> Enum.map(&parse/1)
    |> Enum.reverse()
    |> Enum.reduce({MapSet.new(), []}, fn parsed, {seen, acc} ->
      keep? = !MapSet.member?(seen, parsed.key)
      seen = MapSet.put(seen, parsed.key)

      if keep?,
        do: {seen, [parsed.class | acc]},
        else: {seen, acc}
    end)
    |> elem(1)
  end

  defp parse(class) do
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
    key = {modifiers, important?, group}

    %{
      class: class,
      group: group,
      modifiers: "",
      important?: important?,
      key: key
    }
  end

  def flatten(nil), do: []
  def flatten(false), do: []
  def flatten({_class, nil}), do: []
  def flatten({_class, false}), do: []
  def flatten({class, true}), do: ["#{class}"]
  def flatten(s) when is_binary(s), do: s |> String.split(" ") |> Enum.map(&String.trim/1)
  def flatten(lst) when is_list(lst), do: Enum.flat_map(lst, &flatten/1)

  defp join(classes) do
    classes
    |> Enum.join(" ")
    |> String.trim()
  end
end
