defmodule TailwindMerge.Parser do
  import NimbleParsec

  # ===== Core Value Parsers =====
  # These are the fundamental building blocks for parsing Tailwind values

  # Integer: any positive integer (e.g., "1", "10", "100")
  integer_value = integer(min: 1)

  # Number: integer with optional decimal (e.g., "1", "1.5", "2.75")
  number_value =
    integer(min: 1)
    |> optional(string(".") |> integer(min: 1))

  # Fraction: numerator/denominator (e.g., "1/2", "3/4", "5/12")
  fraction =
    integer(min: 1)
    |> string("/")
    |> integer(min: 1)

  # Percent: number followed by % (e.g., "50%", "100%", "33.333%")
  _percent =
    number_value
    |> string("%")

  # T-shirt sizes: optional number + size (e.g., "xs", "sm", "md", "lg", "xl", "2xl", "3xl")
  _tshirt_size =
    optional(integer(min: 1))
    |> choice([
      string("xs"),
      string("sm"),
      string("md"),
      string("lg"),
      string("xl")
    ])

  # ===== Unit Parsers =====

  # Basic CSS units
  basic_unit =
    choice([
      string("px"),
      string("rem"),
      string("em"),
      string("pt"),
      string("pc"),
      string("in"),
      string("cm"),
      string("mm"),
      string("%")
    ])

  # Font-relative units
  font_unit =
    choice([
      string("cap"),
      string("ch"),
      string("ex"),
      string("rlh"),
      string("lh")
    ])

  # Viewport units: [s|d|l]?v[h|w|i|b|min|max]
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

  # Container query units: cq[w|h|i|b|min|max]
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

  # Any CSS unit
  any_unit =
    choice([
      container_unit,
      viewport_unit,
      font_unit,
      basic_unit
    ])

  # Length with unit: number + unit (e.g., "10px", "2rem", "50%", "100vh")
  length_with_unit =
    number_value
    |> concat(any_unit)

  # CSS functions: calc, min, max, clamp
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

  # ===== Arbitrary Values =====

  # Arbitrary value: [value] or [label:value]
  # Examples: [10px], [color:blue], [length:2rem]
  arbitrary_value =
    ascii_char([?[])
    |> optional(
      # Optional label: word followed by colon
      ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
      |> string(":")
    )
    |> repeat(
      lookahead_not(ascii_char([?]]))
      |> utf8_char([])
    )
    |> ascii_char([?]])

  # Arbitrary variable: (--var) or (label:--var)
  # Examples: (--my-color), (color:--theme-primary)
  arbitrary_variable =
    ascii_char([?(])
    |> optional(
      # Optional label: word followed by colon
      ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
      |> string(":")
    )
    |> repeat(
      lookahead_not(ascii_char([?)]))
      |> utf8_char([])
    )
    |> ascii_char([?)])

  # ===== Length Parsers =====

  # Arbitrary length: any length value including calc, units, or literal 0
  arbitrary_length =
    choice([
      css_function,
      length_with_unit,
      string("0")
    ])

  # ===== Common Values =====

  none = string("none")
  auto = string("auto")
  full = string("full")

  # ===== Spacing Scale =====
  # Tailwind spacing scale: 0, 0.5, 1, 1.5, 2, 2.5, ..., 96, px, auto, full, arbitrary
  # Reference: https://tailwindcss.com/docs/customizing-spacing

  _spacing_scale =
    choice([
      auto,
      full,
      string("px"),
      # Decimal values: 0.5, 1.5, 2.5, 3.5
      integer(min: 1, max: 3)
      |> string(".")
      |> ascii_char([?5]),
      # Integer values: 1, 2, 3, ..., 96
      integer(min: 1),
      # Zero as a special case
      string("0"),
      fraction,
      arbitrary_length,
      arbitrary_value,
      arbitrary_variable
    ])

  # ===== Sizing Values =====
  # Combines spacing scale with additional sizing keywords

  sizing_scale =
    choice([
      # Viewport units (order matters - longer strings first)
      string("vmin"),
      string("vmax"),
      string("dvw"),
      string("dvh"),
      string("lvw"),
      string("lvh"),
      string("svw"),
      string("svh"),
      string("vw"),
      string("vh"),
      string("vi"),
      string("vb"),
      # Special sizing keywords
      string("screen"),
      string("min"),
      string("max"),
      string("fit"),
      # Standard spacing values
      auto,
      full,
      string("px"),
      # Decimal values: 0.5, 1.5, 2.5, 3.5
      integer(min: 1, max: 3)
      |> string(".")
      |> ascii_char([?5]),
      # Integer values: 1, 2, 3, ...
      integer(min: 1),
      # Zero as a special case
      string("0"),
      fraction,
      arbitrary_length,
      arbitrary_value,
      arbitrary_variable
    ])

  # ===== Color Values =====
  # Supports: named colors, hex, rgb, hsl, arbitrary values

  # Named color with optional opacity (e.g., "red-500", "blue-500/50")
  named_color =
    ascii_string([?a..?z, ?A..?Z], min: 1)
    |> optional(
      string("-")
      |> integer(min: 1)
    )
    |> optional(
      string("/")
      |> choice([
        string("0"),
        integer(min: 1, max: 100),
        arbitrary_value,
        arbitrary_variable
      ])
    )

  # Color functions: rgb, rgba, hsl, hsla, hwb, lab, lch, oklab, oklch, color-mix
  color_function =
    choice([
      string("rgba"),
      string("rgb"),
      string("hsla"),
      string("hsl"),
      string("hwb"),
      string("oklab"),
      string("oklch"),
      string("lab"),
      string("lch"),
      string("color-mix")
    ])
    |> string("(")
    |> repeat(
      lookahead_not(string(")"))
      |> utf8_char([])
    )
    |> string(")")

  # Hex color: #RGB, #RRGGBB, #RRGGBBAA
  hex_color =
    string("#")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 3, max: 8)

  # Any color value
  color_value =
    choice([
      string("transparent"),
      string("current"),
      string("inherit"),
      color_function,
      hex_color,
      named_color,
      arbitrary_value,
      arbitrary_variable
    ])

  # ===== Blend Modes =====

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

  # ===== Class Group Parsers =====
  # These parsers recognize specific Tailwind CSS class groups

  # Display: block, flex, grid, hidden, etc.
  display =
    choice([
      string("block"),
      string("inline-block"),
      string("inline-flex"),
      string("inline-grid"),
      string("inline-table"),
      string("inline"),
      string("flex"),
      string("table-caption"),
      string("table-cell"),
      string("table-column-group"),
      string("table-column"),
      string("table-footer-group"),
      string("table-header-group"),
      string("table-row-group"),
      string("table-row"),
      string("table"),
      string("flow-root"),
      string("grid"),
      string("contents"),
      string("list-item"),
      string("hidden")
    ])
    |> tag(:display)

  # Height: h-{size}
  height =
    string("h-")
    |> concat(sizing_scale)
    |> tag(:height)

  # Stroke width: stroke-{width}
  stroke_width =
    string("stroke-")
    |> choice([
      integer_value,
      arbitrary_length,
      arbitrary_value
    ])
    |> tag(:stroke_width)

  # Stroke color: stroke-{color}
  stroke =
    string("stroke-")
    |> choice([none, color_value])
    |> tag(:stroke)

  # Grayscale: grayscale or grayscale-{value}
  grayscale =
    string("grayscale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        integer_value,
        arbitrary_length,
        arbitrary_value,
        arbitrary_variable
      ])
    ])
    |> tag(:grayscale)

  # Grow: grow or grow-{value}
  grow =
    string("grow")
    |> choice([
      eos(),
      string("-")
      |> choice([
        integer_value,
        arbitrary_length,
        arbitrary_value,
        arbitrary_variable
      ])
    ])
    |> tag(:grow)

  # Mix blend mode: mix-blend-{mode}
  mix_blend =
    string("mix-blend-")
    |> choice([
      string("plus-darker"),
      string("plus-lighter"),
      blend_mode
    ])
    |> tag(:mix_blend)

  # Text decoration: underline, overline, line-through, no-underline
  text_decoration =
    choice([
      string("underline"),
      string("overline"),
      string("line-through"),
      string("no-underline")
    ])
    |> tag(:text_decoration)

  # Overflow: overflow-{value}
  overflow_value =
    choice([
      string("auto"),
      string("hidden"),
      string("clip"),
      string("visible"),
      string("scroll")
    ])

  overflow =
    string("overflow-")
    |> concat(overflow_value)
    |> tag(:overflow)

  # Overflow X: overflow-x-{value}
  overflow_x =
    string("overflow-x-")
    |> concat(overflow_value)
    |> tag(:overflow_x)

  # Overflow Y: overflow-y-{value}
  overflow_y =
    string("overflow-y-")
    |> concat(overflow_value)
    |> tag(:overflow_y)

  # Custom fallback: matches any unrecognized class
  custom = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?/], min: 1)

  # Main class parser: tries each specific parser, falls back to custom
  class =
    choice([
      display,
      height,
      overflow_x,
      overflow_y,
      overflow,
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
