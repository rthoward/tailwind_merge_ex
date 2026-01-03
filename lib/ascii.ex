defmodule TailwindMerge.ASCII do
  def printable(opts \\ []) do
    all_printable = ?\s..?~

    except =
      opts
      |> Keyword.get(:except, [])
      |> List.wrap()

    Enum.reject(all_printable, & &1 in except)
  end
end
