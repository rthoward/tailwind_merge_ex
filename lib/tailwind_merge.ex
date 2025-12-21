defmodule TailwindMerge do
  @moduledoc """
  Documentation for `TailwindMerge`.
  """

  alias TailwindMerge.ConflictingGroups
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
    |> Enum.reduce({MapSet.new(), []}, fn parsed, {seen, acc} ->
      key = Parsed.key(parsed)
      conflicting_groups = ConflictingGroups.conflicts(parsed.group)
      conflicting_keys = Enum.map(conflicting_groups, &Parsed.key(%Parsed{parsed | group: &1}))
      conflicting_keys = [key | conflicting_keys]

      keep? = !Enum.any?([key | conflicting_keys], &MapSet.member?(seen, &1))
      seen = MapSet.put(seen, key)

      if keep?,
        do: {seen, [parsed.class | acc]},
        else: {seen, acc}
    end)
    |> elem(1)
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
