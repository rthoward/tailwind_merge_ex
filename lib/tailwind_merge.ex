defmodule TailwindMerge do
  @moduledoc """
  Documentation for `TailwindMerge`.
  """

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

  defp merge(classes), do: classes

  defp flatten(nil), do: []
  defp flatten(false), do: []
  defp flatten({_class, nil}), do: []
  defp flatten({_class, false}), do: []
  defp flatten({class, true}), do: [class]
  defp flatten(s) when is_binary(s), do: [String.trim(s)]
  defp flatten(lst) when is_list(lst), do: Enum.flat_map(lst, &flatten/1)

  defp join(classes) do
    classes
    |> Enum.join(" ")
    |> String.trim()
  end
end
