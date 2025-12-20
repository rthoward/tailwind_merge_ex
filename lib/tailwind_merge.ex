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
    |> Enum.reverse()
    |> Enum.reduce({MapSet.new(), []}, fn class, {seen_groups, acc} ->
      group = group(class)
      keep? = !group || !MapSet.member?(seen_groups, group)
      seen_groups = MapSet.put(seen_groups, group)

      if keep?,
        do: {seen_groups, [class | acc]},
        else: {seen_groups, acc}
    end)
    |> elem(1)
  end

  defp group(class) do
    case Parser.class(class) do
      {:ok, [{grouping, _}], _, _, _, _} -> grouping
      _ -> nil
    end
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
