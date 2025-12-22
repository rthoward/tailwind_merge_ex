defmodule TailwindMerge do
  @moduledoc """
  Documentation for `TailwindMerge`.
  """

  alias TailwindMerge.Conflicts
  alias TailwindMerge.Parsed

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
    |> Enum.map(&Parsed.new/1)
    |> Enum.reverse()
    |> Enum.reduce({%{}, []}, fn parsed, {seen_groups, acc} ->
      dbg(parsed)
      conflicting_groups = Conflicts.groups(parsed.group)
      group_match = get_in(seen_groups, [parsed.group, parsed.modifiers])
      conflict? = !is_nil(group_match) && (!parsed.important? || group_match)

      seen_groups =
        Enum.reduce(conflicting_groups, seen_groups, fn group, seen_groups ->
          Map.put(seen_groups, group, %{parsed.modifiers => parsed.important?})
        end)

      if !conflict?,
        do: {seen_groups, [parsed.class | acc]},
        else: {seen_groups, acc}
    end)
    |> elem(1)
  end

  def flatten(nil), do: []
  def flatten(false), do: []
  def flatten({_class, nil}), do: []
  def flatten({_class, false}), do: []
  def flatten({class, true}), do: ["#{class}"]
  def flatten(s) when is_binary(s), do: s |> String.split(~r/\s+/, trim: true)
  def flatten(lst) when is_list(lst), do: Enum.flat_map(lst, &flatten/1)

  defp join(classes) do
    classes
    |> Enum.join(" ")
    |> String.trim()
  end
end
