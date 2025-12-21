defmodule TailwindMerge.Parser do
  import NimbleParsec

  fraction =
    integer(min: 1)
    |> string("/")
    |> integer(min: 1)

  _tshirt =
    optional(integer(min: 1))
    |> choice([
      string("xs"),
      string("md"),
      string("lg"),
      string("xl")
    ])

  blend_mode =
    choice([
      string("normal"),
      string("multiply"),
      string("screen"),
      string("overlay"),
      string("darken"),
      string("lighten"),
      string("color-dodge"),
      string("color-burn"),
      string("hard-light"),
      string("soft-light"),
      string("difference"),
      string("exclusion"),
      string("hue"),
      string("saturation"),
      string("color"),
      string("luminosity")
    ])

  none = string("none")

  arbitrary_value =
    ascii_char([?[])
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?%], min: 1)
    |> ascii_char([?]])

  basic_unit =
    choice([
      string("%"),
      string("px"),
      string("rem"),
      string("em"),
      string("pt"),
      string("pc"),
      string("in"),
      string("cm"),
      string("mm")
    ])

  font_unit =
    choice([
      string("cap"),
      string("ch"),
      string("ex"),
      string("rlh"),
      string("lh")
    ])

  viewport_unit =
    optional(choice([string("s"), string("d"), string("l")]))
    |> string("v")
    |> choice([
      string("min"),
      string("max"),
      string("h"),
      string("w"),
      string("i"),
      string("b")
    ])

  container_unit =
    string("cq")
    |> choice([
      string("min"),
      string("max"),
      string("w"),
      string("h"),
      string("i"),
      string("b")
    ])

  numeric_with_unit =
    integer(min: 1)
    |> choice([
      container_unit,
      viewport_unit,
      font_unit,
      basic_unit
    ])

  css_function =
    choice([
      string("calc"),
      string("min"),
      string("max"),
      string("clamp")
    ])
    |> string("(")
    |> repeat(
      lookahead_not(string(")"))
      |> utf8_char([])
    )
    |> string(")")

  arbitrary_length =
    choice([css_function, numeric_with_unit, string("0")])

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

  custom = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)

  stroke_width =
    string("stroke-")
    |> choice([
      integer(min: 1),
      arbitrary_length,
      arbitrary_value
    ])
    |> tag(:stroke_width)

  stroke =
    string("stroke-")
    |> choice([none, color])
    |> tag(:stroke)

  grayscale =
    string("grayscale")
    |> choice([
      eos(),
      ascii_char([?-]) |> concat(arbitrary_length),
      ascii_char([?-]) |> concat(arbitrary_value)
    ])
    |> tag(:grayscale)

  grow =
    string("grow")
    |> choice([
      eos(),
      ascii_char([?-]) |> concat(arbitrary_length),
      ascii_char([?-]) |> concat(arbitrary_value)
    ])
    |> tag(:grow)

  mix_blend =
    string("mix-blend-")
    |> choice([
      string("plus-darker"),
      string("plus-lighter"),
      blend_mode
    ])
    |> tag(:mix_blend)

  text_decoration =
    choice([
      string("underline"),
      string("overline"),
      string("line-through"),
      string("no-underline")
    ])
    |> tag(:text_decoration)

  class =
    choice([
      display,
      height,
      stroke_width,
      stroke,
      grayscale,
      grow,
      mix_blend,
      text_decoration,
      custom
    ])

  defparsec(:class, class)
end
