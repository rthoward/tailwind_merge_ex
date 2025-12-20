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
    |> resolve()
  end

  defp parse(class), do: %{class: class, group: group(class)}

  defp resolve(classes) do
    classes
    |> Enum.reverse()
    |> Enum.uniq_by(& &1.group)
    |> Enum.reverse()
    |> Enum.map(& &1.class)
  end

  def group(class) do
    case Parser.class(class) do
      {:ok, [{grouping, _}], _, _, _, _} -> grouping
      _ -> :custom
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
