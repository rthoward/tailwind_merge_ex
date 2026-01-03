defmodule TailwindMerge.ASCII do
  def printable(opts \\ []) do
    all_printable = ?\s..?~

    except =
      opts
      |> Keyword.get(:except, [])
      |> List.wrap()

    Enum.reject(all_printable, &(&1 in except))
  end

  defmacro labelled_var(labels) do
    label_choices = quote do: choice(Enum.map(unquote(labels), &string(&1)))

    quote do
      ignore(string("("))
      |> unquote(label_choices)
      |> ignore(string(":"))
      |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-, ?_], min: 1)
      |> ignore(string(")"))
    end
  end

  defmacro labelled_val(labels) do
    label_choices = quote do: choice(Enum.map(unquote(labels), &string(&1)))

    quote do
      ignore(string("["))
      |> unquote(label_choices)
      |> ignore(string(":"))
      |> ascii_string(printable(except: ?]), min: 1)
      |> ignore(string("]"))
    end
  end
end
