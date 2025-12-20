defmodule TailwindMerge.Parser do
  import NimbleParsec

  fraction =
    integer(min: 1)
    |> string("/")
    |> integer(min: 1)

  tshirt =
    optional(integer(min: 1))
    |> choice([
      string("xs"),
      string("md"),
      string("lg"),
      string("xl"),
    ]
    )

  arbitrary_value =
    ascii_char([?[])
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
    |> ascii_char([?]])

  arbitrary_variable =
    ascii_char([?(])
    |> ascii_string([?a..?z, ?-], min: 1)
    |> ascii_char([?)])

  scale_sizing =
    choice([
      string("auto"),
      string("full"),
      string("dvw"),
      string("dvh"),
      string("lvw"),
      string("lvh"),
      string("svw"),
      string("svh"),
      string("min"),
      string("max"),
      string("fit"),
      integer(min: 1),
      fraction,
      arbitrary_value
    ])

  display =
    choice([
      string("block"),
      string("inline-block"),
      string("inline"),
      string("flex"),
      string("inline-flex"),
      string("table"),
      string("inline-table"),
      string("table-caption"),
      string("table-cell"),
      string("table-column"),
      string("table-column-group"),
      string("table-footer-group"),
      string("table-header-group"),
      string("table-row-group"),
      string("table-row"),
      string("flow-root"),
      string("grid"),
      string("inline-grid"),
      string("contents"),
      string("list-item"),
      string("hidden")
    ])
    |> tag(:display)

  height =
    string("h-")
    |> concat(scale_sizing)
    |> tag(:height)

  color =
  ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
  |> tag(:color)

  custom =
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
    |> tag(:custom)

  scale =
    string("scale-")
    |> choice([color, arbitrary_value, arbitrary_variable])
    |> tag(:scale)

  class =
    choice([
      display,
      height,
      scale,
      custom
    ])

  defparsec :class, class
end
