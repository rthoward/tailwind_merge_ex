defmodule TailwindMerge do
  @moduledoc """
  Documentation for `TailwindMerge`.
  """

  @arbitrary_value ~r/^\[(?:(\w[\w-]*):)?(.+)\]$/i
  @arbitrary_var ~r/^\((?:(\w[\w-]*):)?(.+)\)$/i
  @fraction ~r/^\d+\/\d+$/
  @tshirt ~r/^(\d+(\.\d+)?)?(xs|sm|md|lg|xl)$/
  @length ~r/\d+(%|px|r?em|[sdl]?v([hwib]|min|max)|pt|pc|in|cm|mm|cap|ch|ex|r?lh|cq(w|h|i|b|min|max))|\b(calc|min|max|clamp)\(.+\)|^0$/
  @color_fn ~r/^(rgba?|hsla?|hwb|(ok)?(lab|lch)|color-mix)\(.+\)$/
  @shadow ~r/^(inset_)?-?((\d+)?\.?(\d+)[a-z]+|0)_-?((\d+)?\.?(\d+)[a-z]+|0)/
  @image ~r/^(url|image|image-set|cross-fade|element|(repeating-)?(linear|radial|conic)-gradient)\(.+\)$/

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
    |> dbg()
    |> resolve()
  end

  defp parse(class), do: %{class: class, group: group(class)}
  defp resolve(classes), do: Enum.map(classes, & &1.class)

  defp group("p-"), do: :padding
  defp group("px-"), do: :padding_x
  defp group("py-"), do: :padding_y

  defp group("block"), do: :display
  defp group("inline"), do: :display
  defp group("flex"), do: :display
  defp group("inline-block"), do: :display
  defp group("inline-flex"), do: :display

  defp group(_), do: :custom

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

  defp number?(x), do: Integer.parse(x) != :error
  defp fraction?(x), do: Regex.match?(@fraction, x)
  defp arbitrary_value?(x), do: Regex.match?(@arbitrary_value, x)
  defp arbitrary_var(x), do: Regex.match?(@arbitrary_var, x)
  defp length?(x), do: Regex.match?(@length, x)

  defp scale_spacing?("auto"), do: true
  defp scale_spacing?("full"), do: true
  defp scale_spacing?("dvw"), do: true
  defp scale_spacing?("dvh"), do: true
  defp scale_spacing?("lvw"), do: true
  defp scale_spacing?("lvh"), do: true
  defp scale_spacing?("svw"), do: true
  defp scale_spacing?("svh"), do: true
  defp scale_spacing?("min"), do: true
  defp scale_spacing?("max"), do: true
  defp scale_spacing?("fit"), do: true
  defp scale_spacing?(x)

  def theme do
    %{
      spacing: &number?/1
    }
  end
end
