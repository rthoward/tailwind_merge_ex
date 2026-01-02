defmodule TailwindMerge.ASCII do
  def printable(opts \\ []) do
    except = MapSet.new(opts[:except] || [])
    all_printable = ?\s..?~

    Enum.reject(all_printable, & &1 in except)
  end
end
