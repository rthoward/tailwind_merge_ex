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
      string("clamp"),
      string("theme")
    ])
    |> string("(")
    |> choice([
      parsec(:css_function),
      ascii_string([?a..?z, ?A..?Z, ?0..?9, ?., ?-, ?/], min: 0)
    ])
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?., ?-, ?/], min: 0)
    |> string(")")

  defparsec(:css_function, css_function)

  # ===== Arbitrary Values =====
  # These are defined as defcombinatorp for performance (heavily reused)

  # Arbitrary value: [value] or [label:value]
  # Examples: [10px], [color:blue], [length:2rem]
  arbitrary_value_combinator =
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

  defcombinatorp(:arbitrary_value, arbitrary_value_combinator)

  # Arbitrary variable: (--var) or (label:--var)
  # Examples: (--my-color), (color:--theme-primary)
  arbitrary_variable_combinator =
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

  defcombinatorp(:arbitrary_variable, arbitrary_variable_combinator)

  # ===== Length Parsers =====

  length_variable =
    string("length:")
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?., ?-, ?(, ?), ?/], min: 1)

  # Arbitrary length: any length value including calc, units, or literal 0
  arbitrary_length_combinator =
    ascii_char([?[])
    |> choice([css_function, length_variable, length_with_unit, string("0")])
    |> ascii_char([?]])

  defparsec(:arbitrary_length, arbitrary_length_combinator)

  # ===== Common Values =====

  none = string("none")
  auto = string("auto")
  full = string("full")

  # ===== Spacing Scale =====
  # Tailwind spacing scale: 0, 0.5, 1, 1.5, 2, 2.5, ..., 96, px, auto, full, arbitrary
  # Reference: https://tailwindcss.com/docs/customizing-spacing

  spacing_scale_combinator =
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
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])

  defcombinatorp(:spacing_scale, spacing_scale_combinator)

  # ===== Sizing Values =====
  # Combines spacing scale with additional sizing keywords

  sizing_scale_combinator =
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
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])

  defcombinatorp(:sizing_scale, sizing_scale_combinator)

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
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
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
    |> ascii_char([?(])
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?%], min: 1)
    |> ascii_char([?)])

  defparsec(:color_function, color_function)

  # Hex color: #RGB, #RRGGBB, #RRGGBBAA
  hex_color =
    string("#")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 3, max: 8)

  # Any color value
  color_value_combinator =
    choice([
      string("transparent"),
      string("current"),
      string("inherit"),
      string("color:0"),
      color_function,
      hex_color,
      named_color
    ])

  defcombinatorp(:color_value, color_value_combinator)

  arbitrary_color_value =
    ascii_char([?[])
    |> parsec(:color_value)
    |> ascii_char([?]])

  # ===== Color Classes =====

  # Background color: bg-{color}
  bg =
    string("bg-")
    |> concat(parsec(:color_value))
    |> tag(:bg)

  # Text color: text-{color}
  text_color =
    string("text-")
    |> choice([parsec(:color_value), arbitrary_color_value])
    |> tag(:text_color)

  # Border color: border-{color}
  border_color =
    string("border-")
    |> concat(parsec(:color_value))
    |> tag(:border_color)

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

  # ===== Advanced Features Classes =====

  # Transforms
  rotate =
    string("rotate-")
    |> choice([
      string("0"),
      string("1"),
      string("2"),
      string("3"),
      string("6"),
      string("12"),
      string("45"),
      string("90"),
      string("180"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:rotate)

  scale =
    string("scale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        string("50"),
        string("75"),
        string("90"),
        string("95"),
        string("100"),
        string("105"),
        string("110"),
        string("125"),
        string("150"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:scale)

  scale_x =
    string("scale-x-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("90"),
      string("95"),
      string("100"),
      string("105"),
      string("110"),
      string("125"),
      string("150"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:scale_x)

  scale_y =
    string("scale-y-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("90"),
      string("95"),
      string("100"),
      string("105"),
      string("110"),
      string("125"),
      string("150"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:scale_y)

  skew_x =
    string("skew-x-")
    |> choice([
      string("0"),
      string("1"),
      string("2"),
      string("3"),
      string("6"),
      string("12"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:skew_x)

  skew_y =
    string("skew-y-")
    |> choice([
      string("0"),
      string("1"),
      string("2"),
      string("3"),
      string("6"),
      string("12"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:skew_y)

  translate_x =
    string("translate-x-")
    |> concat(parsec(:spacing_scale))
    |> tag(:translate_x)

  translate_y =
    string("translate-y-")
    |> concat(parsec(:spacing_scale))
    |> tag(:translate_y)

  translate_none =
    string("translate-none")
    |> eos()
    |> tag(:translate_none)

  transform_origin =
    string("origin-")
    |> choice([
      string("center"),
      string("top-right"),
      string("top-left"),
      string("top"),
      string("bottom-right"),
      string("bottom-left"),
      string("bottom"),
      string("right"),
      string("left"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:transform_origin)

  perspective =
    string("perspective-")
    |> choice([
      string("none"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:perspective)

  perspective_origin =
    string("perspective-origin-")
    |> choice([
      string("center"),
      string("top-right"),
      string("top-left"),
      string("top"),
      string("bottom-right"),
      string("bottom-left"),
      string("bottom"),
      string("right"),
      string("left"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:perspective_origin)

  # Transitions & Animations
  transition =
    string("transition")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("all"),
        string("colors"),
        string("opacity"),
        string("shadow"),
        string("transform"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:transition)

  duration =
    string("duration-")
    |> choice([
      string("0"),
      string("75"),
      string("100"),
      string("150"),
      string("200"),
      string("300"),
      string("500"),
      string("700"),
      string("1000"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:duration)

  ease =
    string("ease-")
    |> choice([
      string("linear"),
      string("in-out"),
      string("in"),
      string("out"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:ease)

  delay =
    string("delay-")
    |> choice([
      string("0"),
      string("75"),
      string("100"),
      string("150"),
      string("200"),
      string("300"),
      string("500"),
      string("700"),
      string("1000"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:delay)

  animate =
    string("animate-")
    |> choice([
      string("none"),
      string("spin"),
      string("ping"),
      string("pulse"),
      string("bounce"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:animate)

  # Tables
  border_collapse =
    string("border-")
    |> choice([
      string("collapse"),
      string("separate")
    ])
    |> eos()
    |> tag(:border_collapse)

  border_spacing =
    string("border-spacing-")
    |> concat(parsec(:spacing_scale))
    |> tag(:border_spacing)

  border_spacing_x =
    string("border-spacing-x-")
    |> concat(parsec(:spacing_scale))
    |> tag(:border_spacing_x)

  border_spacing_y =
    string("border-spacing-y-")
    |> concat(parsec(:spacing_scale))
    |> tag(:border_spacing_y)

  table_layout =
    string("table-")
    |> choice([
      string("auto"),
      string("fixed")
    ])
    |> eos()
    |> tag(:table_layout)

  caption =
    string("caption-")
    |> choice([
      string("top"),
      string("bottom")
    ])
    |> eos()
    |> tag(:caption)

  # Interactivity
  cursor =
    string("cursor-")
    |> choice([
      string("auto"),
      string("default"),
      string("pointer"),
      string("wait"),
      string("text"),
      string("move"),
      string("help"),
      string("not-allowed"),
      string("none"),
      string("context-menu"),
      string("progress"),
      string("cell"),
      string("crosshair"),
      string("vertical-text"),
      string("alias"),
      string("copy"),
      string("no-drop"),
      string("grab"),
      string("grabbing"),
      string("all-scroll"),
      string("col-resize"),
      string("row-resize"),
      string("n-resize"),
      string("e-resize"),
      string("s-resize"),
      string("w-resize"),
      string("ne-resize"),
      string("nw-resize"),
      string("se-resize"),
      string("sw-resize"),
      string("ew-resize"),
      string("ns-resize"),
      string("nesw-resize"),
      string("nwse-resize"),
      string("zoom-in"),
      string("zoom-out"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:cursor)

  pointer_events =
    string("pointer-events-")
    |> choice([
      string("none"),
      string("auto")
    ])
    |> eos()
    |> tag(:pointer_events)

  resize =
    string("resize")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("y"),
        string("x")
      ])
    ])
    |> tag(:resize)

  scroll_behavior =
    string("scroll-")
    |> choice([
      string("auto"),
      string("smooth")
    ])
    |> eos()
    |> tag(:scroll_behavior)

  scroll_m =
    string("scroll-m-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_m)

  scroll_mx =
    string("scroll-mx-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_mx)

  scroll_my =
    string("scroll-my-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_my)

  scroll_ms =
    string("scroll-ms-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_ms)

  scroll_me =
    string("scroll-me-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_me)

  scroll_mt =
    string("scroll-mt-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_mt)

  scroll_mr =
    string("scroll-mr-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_mr)

  scroll_mb =
    string("scroll-mb-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_mb)

  scroll_ml =
    string("scroll-ml-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_ml)

  scroll_p =
    string("scroll-p-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_p)

  scroll_px =
    string("scroll-px-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_px)

  scroll_py =
    string("scroll-py-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_py)

  scroll_ps =
    string("scroll-ps-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_ps)

  scroll_pe =
    string("scroll-pe-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_pe)

  scroll_pt =
    string("scroll-pt-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_pt)

  scroll_pr =
    string("scroll-pr-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_pr)

  scroll_pb =
    string("scroll-pb-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_pb)

  scroll_pl =
    string("scroll-pl-")
    |> concat(parsec(:spacing_scale))
    |> tag(:scroll_pl)

  snap_align =
    string("snap-")
    |> choice([
      string("start"),
      string("end"),
      string("center"),
      string("align-none")
    ])
    |> eos()
    |> tag(:snap_align)

  snap_stop =
    string("snap-")
    |> choice([
      string("normal"),
      string("always")
    ])
    |> eos()
    |> tag(:snap_stop)

  snap_type =
    string("snap-")
    |> choice([
      string("none"),
      string("x"),
      string("y"),
      string("both")
    ])
    |> eos()
    |> tag(:snap_type)

  touch =
    string("touch-")
    |> choice([
      string("auto"),
      string("none"),
      string("manipulation")
    ])
    |> eos()
    |> tag(:touch)

  touch_x =
    string("touch-pan-")
    |> choice([
      string("x"),
      string("left"),
      string("right")
    ])
    |> eos()
    |> tag(:touch_x)

  touch_y =
    string("touch-pan-")
    |> choice([
      string("y"),
      string("up"),
      string("down")
    ])
    |> eos()
    |> tag(:touch_y)

  touch_pz =
    string("touch-pinch-zoom")
    |> eos()
    |> tag(:touch_pz)

  user_select =
    string("select-")
    |> choice([
      string("none"),
      string("text"),
      string("all"),
      string("auto")
    ])
    |> eos()
    |> tag(:user_select)

  will_change =
    string("will-change-")
    |> choice([
      string("auto"),
      string("scroll"),
      string("contents"),
      string("transform"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:will_change)

  # SVG
  fill =
    string("fill-")
    |> choice([
      none,
      parsec(:color_value)
    ])
    |> tag(:fill)

  # ===== Visual Effects Classes =====

  # Backgrounds
  bg_attachment =
    string("bg-")
    |> choice([
      string("fixed"),
      string("local"),
      string("scroll")
    ])
    |> eos()
    |> tag(:bg_attachment)

  bg_clip =
    string("bg-clip-")
    |> choice([
      string("border"),
      string("padding"),
      string("content"),
      string("text")
    ])
    |> eos()
    |> tag(:bg_clip)

  bg_origin =
    string("bg-origin-")
    |> choice([
      string("border"),
      string("padding"),
      string("content")
    ])
    |> eos()
    |> tag(:bg_origin)

  bg_position =
    string("bg-")
    |> choice([
      string("bottom"),
      string("center"),
      string("left-bottom"),
      string("left-top"),
      string("left"),
      string("right-bottom"),
      string("right-top"),
      string("right"),
      string("top"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:bg_position)

  bg_repeat =
    string("bg-")
    |> choice([
      string("repeat-x"),
      string("repeat-y"),
      string("repeat-round"),
      string("repeat-space"),
      string("no-repeat"),
      string("repeat")
    ])
    |> eos()
    |> tag(:bg_repeat)

  bg_size =
    string("bg-")
    |> choice([
      string("auto"),
      string("cover"),
      string("contain"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:bg_size)

  bg_image =
    string("bg-")
    |> choice([
      string("none"),
      string("gradient-to-t"),
      string("gradient-to-tr"),
      string("gradient-to-r"),
      string("gradient-to-br"),
      string("gradient-to-b"),
      string("gradient-to-bl"),
      string("gradient-to-l"),
      string("gradient-to-tl"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:bg_image)

  gradient_from_pos =
    string("from-")
    |> choice([
      string("0%"),
      string("5%"),
      string("10%"),
      string("15%"),
      string("20%"),
      string("25%"),
      string("30%"),
      string("35%"),
      string("40%"),
      string("45%"),
      string("50%"),
      string("55%"),
      string("60%"),
      string("65%"),
      string("70%"),
      string("75%"),
      string("80%"),
      string("85%"),
      string("90%"),
      string("95%"),
      string("100%"),
      parsec(:arbitrary_value)
    ])
    |> tag(:gradient_from_pos)

  gradient_via_pos =
    string("via-")
    |> choice([
      string("0%"),
      string("5%"),
      string("10%"),
      string("15%"),
      string("20%"),
      string("25%"),
      string("30%"),
      string("35%"),
      string("40%"),
      string("45%"),
      string("50%"),
      string("55%"),
      string("60%"),
      string("65%"),
      string("70%"),
      string("75%"),
      string("80%"),
      string("85%"),
      string("90%"),
      string("95%"),
      string("100%"),
      parsec(:arbitrary_value)
    ])
    |> tag(:gradient_via_pos)

  gradient_to_pos =
    string("to-")
    |> choice([
      string("0%"),
      string("5%"),
      string("10%"),
      string("15%"),
      string("20%"),
      string("25%"),
      string("30%"),
      string("35%"),
      string("40%"),
      string("45%"),
      string("50%"),
      string("55%"),
      string("60%"),
      string("65%"),
      string("70%"),
      string("75%"),
      string("80%"),
      string("85%"),
      string("90%"),
      string("95%"),
      string("100%"),
      parsec(:arbitrary_value)
    ])
    |> tag(:gradient_to_pos)

  gradient_from =
    string("from-")
    |> concat(parsec(:color_value))
    |> tag(:gradient_from)

  gradient_via =
    string("via-")
    |> concat(parsec(:color_value))
    |> tag(:gradient_via)

  gradient_to =
    string("to-")
    |> concat(parsec(:color_value))
    |> tag(:gradient_to)

  # Borders & Outlines
  rounded =
    string("rounded")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("sm"),
        string("md"),
        string("lg"),
        string("xl"),
        string("2xl"),
        string("3xl"),
        string("full"),
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:rounded)

  side =
    choice([
      string("x"),
      string("y"),
      string("t"),
      string("b"),
      string("l"),
      string("r"),
      string("s"),
      string("e")
    ])

  border_w =
    string("border")
    |> choice([
      eos(),
      string("-") |> integer(min: 1),
      string("-") |> concat(side) |> optional(string("-") |> integer(min: 1)),
      integer(min: 1),
      parsec(:arbitrary_length),
      parsec(:arbitrary_variable)
    ])
    |> tag(:border_w)

  border_style =
    string("border-")
    |> choice([
      string("solid"),
      string("dashed"),
      string("dotted"),
      string("double"),
      string("hidden"),
      string("none")
    ])
    |> eos()
    |> tag(:border_style)

  divide_x =
    string("divide-x")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        string("2"),
        string("4"),
        string("8"),
        string("reverse"),
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:divide_x)

  divide_y =
    string("divide-y")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        string("2"),
        string("4"),
        string("8"),
        string("reverse"),
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:divide_y)

  divide_style =
    string("divide-")
    |> choice([
      string("solid"),
      string("dashed"),
      string("dotted"),
      string("double"),
      string("none")
    ])
    |> eos()
    |> tag(:divide_style)

  divide_color =
    string("divide-")
    |> concat(parsec(:color_value))
    |> tag(:divide_color)

  outline_style =
    string("outline-")
    |> choice([
      string("none"),
      string("solid"),
      string("dashed"),
      string("dotted"),
      string("double")
    ])
    |> eos()
    |> tag(:outline_style)

  outline_w =
    string("outline-")
    |> choice([
      string("0"),
      string("1"),
      string("2"),
      string("4"),
      string("8"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:outline_w)

  outline_offset =
    string("outline-offset-")
    |> choice([
      string("0"),
      string("1"),
      string("2"),
      string("4"),
      string("8"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:outline_offset)

  outline_color =
    string("outline-")
    |> concat(parsec(:color_value))
    |> tag(:outline_color)

  # Effects
  shadow =
    string("shadow")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("sm"),
        string("md"),
        string("lg"),
        string("xl"),
        string("2xl"),
        string("inner"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:shadow)

  shadow_color =
    string("shadow-")
    |> concat(parsec(:color_value))
    |> tag(:shadow_color)

  opacity =
    string("opacity-")
    |> choice([
      string("0"),
      string("5"),
      string("10"),
      string("15"),
      string("20"),
      string("25"),
      string("30"),
      string("35"),
      string("40"),
      string("45"),
      string("50"),
      string("55"),
      string("60"),
      string("65"),
      string("70"),
      string("75"),
      string("80"),
      string("85"),
      string("90"),
      string("95"),
      string("100"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:opacity)

  bg_blend =
    string("bg-blend-")
    |> concat(blend_mode)
    |> tag(:bg_blend)

  # Filters
  blur =
    string("blur")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("sm"),
        string("md"),
        string("lg"),
        string("xl"),
        string("2xl"),
        string("3xl"),
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:blur)

  brightness =
    string("brightness-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("90"),
      string("95"),
      string("100"),
      string("105"),
      string("110"),
      string("125"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:brightness)

  contrast =
    string("contrast-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("100"),
      string("125"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:contrast)

  drop_shadow =
    string("drop-shadow")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("sm"),
        string("md"),
        string("lg"),
        string("xl"),
        string("2xl"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:drop_shadow)

  hue_rotate =
    string("hue-rotate-")
    |> choice([
      string("0"),
      string("15"),
      string("30"),
      string("60"),
      string("90"),
      string("180"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:hue_rotate)

  invert =
    string("invert")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:invert)

  saturate =
    string("saturate-")
    |> choice([
      string("0"),
      string("50"),
      string("100"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:saturate)

  sepia =
    string("sepia")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:sepia)

  backdrop_blur =
    string("backdrop-blur")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("sm"),
        string("md"),
        string("lg"),
        string("xl"),
        string("2xl"),
        string("3xl"),
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:backdrop_blur)

  backdrop_brightness =
    string("backdrop-brightness-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("90"),
      string("95"),
      string("100"),
      string("105"),
      string("110"),
      string("125"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:backdrop_brightness)

  backdrop_contrast =
    string("backdrop-contrast-")
    |> choice([
      string("0"),
      string("50"),
      string("75"),
      string("100"),
      string("125"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:backdrop_contrast)

  backdrop_grayscale =
    string("backdrop-grayscale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:backdrop_grayscale)

  backdrop_hue_rotate =
    string("backdrop-hue-rotate-")
    |> choice([
      string("0"),
      string("15"),
      string("30"),
      string("60"),
      string("90"),
      string("180"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:backdrop_hue_rotate)

  backdrop_invert =
    string("backdrop-invert")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:backdrop_invert)

  backdrop_opacity =
    string("backdrop-opacity-")
    |> choice([
      string("0"),
      string("5"),
      string("10"),
      string("15"),
      string("20"),
      string("25"),
      string("30"),
      string("35"),
      string("40"),
      string("45"),
      string("50"),
      string("55"),
      string("60"),
      string("65"),
      string("70"),
      string("75"),
      string("80"),
      string("85"),
      string("90"),
      string("95"),
      string("100"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:backdrop_opacity)

  backdrop_saturate =
    string("backdrop-saturate-")
    |> choice([
      string("0"),
      string("50"),
      string("100"),
      string("150"),
      string("200"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:backdrop_saturate)

  backdrop_sepia =
    string("backdrop-sepia")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
      ])
    ])
    |> tag(:backdrop_sepia)

  # ===== Layout & Positioning Classes =====

  # Aspect ratio: aspect-{ratio}
  aspect =
    string("aspect-")
    |> choice([
      string("auto"),
      string("square"),
      string("video"),
      fraction,
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:aspect)

  # Container: container
  container =
    string("container")
    |> eos()
    |> tag(:container)

  # Columns: columns-{n}
  columns =
    string("columns-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:columns)

  # Break after: break-after-{value}
  break_after =
    string("break-after-")
    |> choice([
      string("auto"),
      string("avoid"),
      string("all"),
      string("avoid-page"),
      string("page"),
      string("left"),
      string("right"),
      string("column")
    ])
    |> tag(:break_after)

  # Break before: break-before-{value}
  break_before =
    string("break-before-")
    |> choice([
      string("auto"),
      string("avoid"),
      string("all"),
      string("avoid-page"),
      string("page"),
      string("left"),
      string("right"),
      string("column")
    ])
    |> tag(:break_before)

  # Break inside: break-inside-{value}
  break_inside =
    string("break-inside-")
    |> choice([
      string("auto"),
      string("avoid"),
      string("avoid-page"),
      string("avoid-column")
    ])
    |> tag(:break_inside)

  # Box decoration: box-decoration-{slice/clone}
  box_decoration =
    string("box-decoration-")
    |> choice([
      string("slice"),
      string("clone")
    ])
    |> tag(:box_decoration)

  # Box sizing: box-{border/content}
  box =
    string("box-")
    |> choice([
      string("border"),
      string("content")
    ])
    |> tag(:box)

  # Screen reader: sr-only, not-sr-only
  sr =
    choice([
      string("sr-only"),
      string("not-sr-only")
    ])
    |> eos()
    |> tag(:sr)

  # Float: float-{direction}
  float =
    string("float-")
    |> choice([
      string("start"),
      string("end"),
      string("right"),
      string("left"),
      string("none")
    ])
    |> tag(:float)

  # Clear: clear-{direction}
  clear =
    string("clear-")
    |> choice([
      string("start"),
      string("end"),
      string("left"),
      string("right"),
      string("both"),
      string("none")
    ])
    |> tag(:clear)

  # Isolation: isolate, isolation-auto
  isolation =
    choice([
      string("isolation-auto"),
      string("isolate")
    ])
    |> eos()
    |> tag(:isolation)

  # Object fit: object-{fit}
  object_fit =
    string("object-")
    |> choice([
      string("contain"),
      string("cover"),
      string("fill"),
      string("none"),
      string("scale-down")
    ])
    |> tag(:object_fit)

  # Object position: object-{position}
  object_position =
    string("object-")
    |> choice([
      string("bottom"),
      string("center"),
      string("left-bottom"),
      string("left-top"),
      string("left"),
      string("right-bottom"),
      string("right-top"),
      string("right"),
      string("top"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:object_position)

  # Position: static, fixed, absolute, relative, sticky
  position =
    choice([
      string("static"),
      string("fixed"),
      string("absolute"),
      string("relative"),
      string("sticky")
    ])
    |> eos()
    |> tag(:position)

  # Inset: inset-{size}
  inset =
    string("inset-")
    |> concat(parsec(:spacing_scale))
    |> tag(:inset)

  # Inset X: inset-x-{size}
  inset_x =
    string("inset-x-")
    |> concat(parsec(:spacing_scale))
    |> tag(:inset_x)

  # Inset Y: inset-y-{size}
  inset_y =
    string("inset-y-")
    |> concat(parsec(:spacing_scale))
    |> tag(:inset_y)

  # Start: start-{size}
  start =
    string("start-")
    |> concat(parsec(:spacing_scale))
    |> tag(:start)

  # End: end-{size}
  end_position =
    string("end-")
    |> concat(parsec(:spacing_scale))
    |> tag(:end)

  # Top: top-{size}
  top =
    string("top-")
    |> concat(parsec(:spacing_scale))
    |> tag(:top)

  # Right: right-{size}
  right =
    string("right-")
    |> concat(parsec(:spacing_scale))
    |> tag(:right)

  # Bottom: bottom-{size}
  bottom =
    string("bottom-")
    |> concat(parsec(:spacing_scale))
    |> tag(:bottom)

  # Left: left-{size}
  left =
    string("left-")
    |> concat(parsec(:spacing_scale))
    |> tag(:left)

  # Visibility: visible, invisible, collapse
  visibility =
    choice([
      string("visible"),
      string("invisible"),
      string("collapse")
    ])
    |> eos()
    |> tag(:visibility)

  # Z-index: z-{index}
  z =
    string("z-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 50),
      string("0"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:z)

  # ===== Typography Classes =====

  # Font size: text-{size}
  font_size =
    string("text-")
    |> choice([
      string("xs"),
      string("sm"),
      string("base"),
      string("lg"),
      string("xl"),
      string("2xl"),
      string("3xl"),
      string("4xl"),
      string("5xl"),
      string("6xl"),
      string("7xl"),
      string("8xl"),
      string("9xl"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_variable)
    ])
    |> tag(:font_size)

  # Font smoothing: antialiased, subpixel-antialiased
  font_smoothing =
    choice([
      string("antialiased"),
      string("subpixel-antialiased")
    ])
    |> eos()
    |> tag(:font_smoothing)

  # Font style: italic, not-italic
  font_style =
    choice([
      string("not-italic"),
      string("italic")
    ])
    |> eos()
    |> tag(:font_style)

  # Font weight: font-{weight}
  font_weight =
    string("font-")
    |> choice([
      string("thin"),
      string("extralight"),
      string("light"),
      string("normal"),
      string("medium"),
      string("semibold"),
      string("bold"),
      string("extrabold"),
      string("black"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:font_weight)

  # Font family: font-{family}
  font_family =
    string("font-")
    |> choice([
      string("sans"),
      string("serif"),
      string("mono"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:font_family)

  # Font variant numeric - normal
  fvn_normal =
    string("normal-nums")
    |> eos()
    |> tag(:fvn_normal)

  # Font variant numeric - ordinal
  fvn_ordinal =
    string("ordinal")
    |> eos()
    |> tag(:fvn_ordinal)

  # Font variant numeric - slashed zero
  fvn_slashed_zero =
    string("slashed-zero")
    |> eos()
    |> tag(:fvn_slashed_zero)

  # Font variant numeric - figure
  fvn_figure =
    choice([
      string("lining-nums"),
      string("oldstyle-nums")
    ])
    |> eos()
    |> tag(:fvn_figure)

  # Font variant numeric - spacing
  fvn_spacing =
    choice([
      string("proportional-nums"),
      string("tabular-nums")
    ])
    |> eos()
    |> tag(:fvn_spacing)

  # Font variant numeric - fraction
  fvn_fraction =
    choice([
      string("diagonal-fractions"),
      string("stacked-fractions")
    ])
    |> eos()
    |> tag(:fvn_fraction)

  # Letter spacing: tracking-{size}
  tracking =
    string("tracking-")
    |> choice([
      string("tighter"),
      string("tight"),
      string("normal"),
      string("wide"),
      string("wider"),
      string("widest"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:tracking)

  # Line clamp: line-clamp-{n}
  line_clamp =
    string("line-clamp-")
    |> choice([
      string("none"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:line_clamp)

  # Line height: leading-{size}
  leading =
    string("leading-")
    |> choice([
      string("none"),
      string("tight"),
      string("snug"),
      string("normal"),
      string("relaxed"),
      string("loose"),
      integer(min: 1, max: 10),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:leading)

  # List image: list-image-{value}
  list_image =
    string("list-image-")
    |> choice([
      string("none"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:list_image)

  # List style position: list-{inside/outside}
  list_style_position =
    string("list-")
    |> choice([
      string("inside"),
      string("outside")
    ])
    |> tag(:list_style_position)

  # List style type: list-{type}
  list_style_type =
    string("list-")
    |> choice([
      string("none"),
      string("disc"),
      string("decimal")
    ])
    |> tag(:list_style_type)

  # Text alignment: text-{align}
  text_alignment =
    string("text-")
    |> choice([
      string("left"),
      string("center"),
      string("right"),
      string("justify"),
      string("start"),
      string("end")
    ])
    |> tag(:text_alignment)

  # Text decoration style: decoration-{style}
  text_decoration_style =
    string("decoration-")
    |> choice([
      string("solid"),
      string("double"),
      string("dotted"),
      string("dashed"),
      string("wavy")
    ])
    |> tag(:text_decoration_style)

  # Text decoration thickness: decoration-{thickness}
  text_decoration_thickness =
    string("decoration-")
    |> choice([
      string("auto"),
      string("from-font"),
      string("0"),
      string("1"),
      string("2"),
      string("4"),
      string("8"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:text_decoration_thickness)

  # Text decoration color: decoration-{color}
  text_decoration_color =
    string("decoration-")
    |> concat(parsec(:color_value))
    |> tag(:text_decoration_color)

  # Underline offset: underline-offset-{size}
  underline_offset =
    string("underline-offset-")
    |> choice([
      string("auto"),
      string("0"),
      string("1"),
      string("2"),
      string("4"),
      string("8"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:underline_offset)

  # Text transform: uppercase, lowercase, capitalize, normal-case
  text_transform =
    choice([
      string("uppercase"),
      string("lowercase"),
      string("capitalize"),
      string("normal-case")
    ])
    |> eos()
    |> tag(:text_transform)

  # Text overflow: truncate, text-ellipsis, text-clip
  text_overflow =
    choice([
      string("truncate"),
      string("text-ellipsis"),
      string("text-clip")
    ])
    |> eos()
    |> tag(:text_overflow)

  # Text wrap: text-{wrap}
  text_wrap =
    string("text-")
    |> choice([
      string("wrap"),
      string("nowrap"),
      string("balance"),
      string("pretty")
    ])
    |> tag(:text_wrap)

  # Text indent: indent-{size}
  indent =
    string("indent-")
    |> concat(parsec(:spacing_scale))
    |> tag(:indent)

  # Vertical align: align-{position}
  vertical_align =
    string("align-")
    |> choice([
      string("baseline"),
      string("top"),
      string("middle"),
      string("bottom"),
      string("text-top"),
      string("text-bottom"),
      string("sub"),
      string("super"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:vertical_align)

  # Whitespace: whitespace-{value}
  whitespace =
    string("whitespace-")
    |> choice([
      string("normal"),
      string("nowrap"),
      string("pre"),
      string("pre-line"),
      string("pre-wrap"),
      string("break-spaces")
    ])
    |> tag(:whitespace)

  # Word break: break-{value}
  word_break =
    string("break-")
    |> choice([
      string("normal"),
      string("words"),
      string("all"),
      string("keep")
    ])
    |> tag(:word_break)

  # Hyphens: hyphens-{value}
  hyphens =
    string("hyphens-")
    |> choice([
      string("none"),
      string("manual"),
      string("auto")
    ])
    |> tag(:hyphens)

  # Content: content-{value}
  content =
    string("content-")
    |> choice([
      string("none"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:content)

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
    |> eos()
    |> tag(:display)

  # ===== Flexbox & Grid Classes =====

  # Flex: flex-{value}
  flex =
    string("flex-")
    |> choice([
      string("1"),
      string("auto"),
      string("initial"),
      string("none"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:flex)

  # Flex direction: flex-row, flex-col, etc.
  flex_direction =
    string("flex-")
    |> choice([
      string("row-reverse"),
      string("col-reverse"),
      string("row"),
      string("col")
    ])
    |> tag(:flex_direction)

  # Flex wrap: flex-wrap, flex-nowrap, etc.
  flex_wrap =
    string("flex-")
    |> choice([
      string("wrap-reverse"),
      string("nowrap"),
      string("wrap")
    ])
    |> tag(:flex_wrap)

  # Justify content: justify-{alignment}
  justify_content =
    string("justify-")
    |> choice([
      string("normal"),
      string("start"),
      string("end"),
      string("center"),
      string("between"),
      string("around"),
      string("evenly"),
      string("stretch")
    ])
    |> tag(:justify_content)

  # Justify items: justify-items-{alignment}
  justify_items =
    string("justify-items-")
    |> choice([
      string("start"),
      string("end"),
      string("center"),
      string("stretch")
    ])
    |> tag(:justify_items)

  # Justify self: justify-self-{alignment}
  justify_self =
    string("justify-self-")
    |> choice([
      string("auto"),
      string("start"),
      string("end"),
      string("center"),
      string("stretch")
    ])
    |> tag(:justify_self)

  # Align content: content-{alignment}
  align_content =
    string("content-")
    |> choice([
      string("normal"),
      string("start"),
      string("end"),
      string("center"),
      string("between"),
      string("around"),
      string("evenly"),
      string("stretch"),
      string("baseline")
    ])
    |> tag(:align_content)

  # Align items: items-{alignment}
  align_items =
    string("items-")
    |> choice([
      string("start"),
      string("end"),
      string("center"),
      string("baseline"),
      string("stretch")
    ])
    |> tag(:align_items)

  # Align self: self-{alignment}
  align_self =
    string("self-")
    |> choice([
      string("auto"),
      string("start"),
      string("end"),
      string("center"),
      string("stretch"),
      string("baseline")
    ])
    |> tag(:align_self)

  # Place content: place-content-{alignment}
  place_content =
    string("place-content-")
    |> choice([
      string("start"),
      string("end"),
      string("center"),
      string("between"),
      string("around"),
      string("evenly"),
      string("stretch"),
      string("baseline")
    ])
    |> tag(:place_content)

  # Place items: place-items-{alignment}
  place_items =
    string("place-items-")
    |> choice([
      string("start"),
      string("end"),
      string("center"),
      string("stretch"),
      string("baseline")
    ])
    |> tag(:place_items)

  # Place self: place-self-{alignment}
  place_self =
    string("place-self-")
    |> choice([
      string("auto"),
      string("start"),
      string("end"),
      string("center"),
      string("stretch")
    ])
    |> tag(:place_self)

  # Gap: gap-{size}
  gap =
    string("gap-")
    |> concat(parsec(:spacing_scale))
    |> tag(:gap)

  # Gap X: gap-x-{size}
  gap_x =
    string("gap-x-")
    |> concat(parsec(:spacing_scale))
    |> tag(:gap_x)

  # Gap Y: gap-y-{size}
  gap_y =
    string("gap-y-")
    |> concat(parsec(:spacing_scale))
    |> tag(:gap_y)

  # Grid columns: grid-cols-{n}
  grid_cols =
    string("grid-cols-")
    |> choice([
      string("subgrid"),
      string("none"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:grid_cols)

  # Column span: col-span-{n}
  col_start_end =
    string("col-span-")
    |> choice([
      string("full"),
      string("auto"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:col_start_end)

  # Column start: col-start-{n}
  col_start =
    string("col-start-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 13),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:col_start)

  # Column end: col-end-{n}
  col_end =
    string("col-end-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 13),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:col_end)

  # Grid rows: grid-rows-{n}
  grid_rows =
    string("grid-rows-")
    |> choice([
      string("subgrid"),
      string("none"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:grid_rows)

  # Row span: row-span-{n}
  row_start_end =
    string("row-span-")
    |> choice([
      string("full"),
      string("auto"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:row_start_end)

  # Row start: row-start-{n}
  row_start =
    string("row-start-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 7),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:row_start)

  # Row end: row-end-{n}
  row_end =
    string("row-end-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 7),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:row_end)

  # Grid flow: grid-flow-{direction}
  grid_flow =
    string("grid-flow-")
    |> choice([
      string("row-dense"),
      string("col-dense"),
      string("dense"),
      string("row"),
      string("col")
    ])
    |> tag(:grid_flow)

  # Auto columns: auto-cols-{size}
  auto_cols =
    string("auto-cols-")
    |> choice([
      string("auto"),
      string("min"),
      string("max"),
      string("fr"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:auto_cols)

  # Auto rows: auto-rows-{size}
  auto_rows =
    string("auto-rows-")
    |> choice([
      string("auto"),
      string("min"),
      string("max"),
      string("fr"),
      parsec(:arbitrary_value),
      parsec(:arbitrary_variable)
    ])
    |> tag(:auto_rows)

  # Height: h-{size}
  h =
    string("h-")
    |> concat(parsec(:sizing_scale))
    |> tag(:height)

  # Stroke width: stroke-{width}
  stroke_width =
    string("stroke-")
    |> choice([
      integer_value,
      parsec(:arbitrary_length)
    ])
    |> tag(:stroke_width)

  # Stroke color: stroke-{color}
  stroke =
    string("stroke-")
    |> choice([none, arbitrary_color_value])
    |> tag(:stroke)

  # Grayscale: grayscale or grayscale-{value}
  grayscale =
    string("grayscale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        integer_value,
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
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
        parsec(:arbitrary_length),
        parsec(:arbitrary_value),
        parsec(:arbitrary_variable)
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

  # ===== Spacing Classes =====
  # Reference: https://tailwindcss.com/docs/padding

  # Padding: p-{size}
  p =
    string("p-")
    |> concat(parsec(:spacing_scale))
    |> tag(:p)

  # Padding X: px-{size}
  px =
    string("px-")
    |> concat(parsec(:spacing_scale))
    |> tag(:px)

  # Padding Y: py-{size}
  py =
    string("py-")
    |> concat(parsec(:spacing_scale))
    |> tag(:py)

  # Padding Start: ps-{size}
  ps =
    string("ps-")
    |> concat(parsec(:spacing_scale))
    |> tag(:ps)

  # Padding End: pe-{size}
  pe =
    string("pe-")
    |> concat(parsec(:spacing_scale))
    |> tag(:pe)

  # Padding Top: pt-{size}
  pt =
    string("pt-")
    |> concat(parsec(:spacing_scale))
    |> tag(:pt)

  # Padding Right: pr-{size}
  pr =
    string("pr-")
    |> concat(parsec(:spacing_scale))
    |> tag(:pr)

  # Padding Bottom: pb-{size}
  pb =
    string("pb-")
    |> concat(parsec(:spacing_scale))
    |> tag(:pb)

  # Padding Left: pl-{size}
  pl =
    string("pl-")
    |> concat(parsec(:spacing_scale))
    |> tag(:pl)

  # Margin: m-{size}
  m =
    string("m-")
    |> concat(parsec(:spacing_scale))
    |> tag(:m)

  # Margin X: mx-{size}
  mx =
    string("mx-")
    |> concat(parsec(:spacing_scale))
    |> tag(:mx)

  # Margin Y: my-{size}
  my =
    string("my-")
    |> concat(parsec(:spacing_scale))
    |> tag(:my)

  # Margin Start: ms-{size}
  ms =
    string("ms-")
    |> concat(parsec(:spacing_scale))
    |> tag(:ms)

  # Margin End: me-{size}
  me =
    string("me-")
    |> concat(parsec(:spacing_scale))
    |> tag(:me)

  # Margin Top: mt-{size}
  mt =
    string("mt-")
    |> concat(parsec(:spacing_scale))
    |> tag(:mt)

  # Margin Right: mr-{size}
  mr =
    string("mr-")
    |> concat(parsec(:spacing_scale))
    |> tag(:mr)

  # Margin Bottom: mb-{size}
  mb =
    string("mb-")
    |> concat(parsec(:spacing_scale))
    |> tag(:mb)

  # Margin Left: ml-{size}
  ml =
    string("ml-")
    |> concat(parsec(:spacing_scale))
    |> tag(:ml)

  # Space Between X: space-x-{size}
  space_x =
    string("space-x-")
    |> concat(parsec(:spacing_scale))
    |> tag(:space_x)

  # Space Between Y: space-y-{size}
  space_y =
    string("space-y-")
    |> concat(parsec(:spacing_scale))
    |> tag(:space_y)

  # ===== Sizing Classes =====
  # Reference: https://tailwindcss.com/docs/width

  # Width: w-{size}
  w =
    string("w-")
    |> concat(parsec(:sizing_scale))
    |> tag(:w)

  # Min Width: min-w-{size}
  min_w =
    string("min-w-")
    |> concat(parsec(:sizing_scale))
    |> tag(:min_w)

  # Max Width: max-w-{size}
  max_w =
    string("max-w-")
    |> concat(parsec(:sizing_scale))
    |> tag(:max_w)

  # Min Height: min-h-{size}
  min_h =
    string("min-h-")
    |> concat(parsec(:sizing_scale))
    |> tag(:min_h)

  # Max Height: max-h-{size}
  max_h =
    string("max-h-")
    |> concat(parsec(:sizing_scale))
    |> tag(:max_h)

  # Size: size-{value} (sets both width and height)
  size =
    string("size-")
    |> concat(parsec(:sizing_scale))
    |> tag(:size)

  custom = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?/], min: 1)

  regular_modifier =
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?/], min: 1)
    |> ignore(ascii_char([?:]))
    |> unwrap_and_tag(:regular_modifier)

  arbitrary_modifier =
    ignore(ascii_char([?[]))
    |> ascii_string([?!..?Z, ?/, ?^..?z], min: 1)
    |> ignore(ascii_char([?]]))
    |> ignore(ascii_char([?:]))
    |> unwrap_and_tag(:arbitrary_modifier)

  modifiers =
    choice([regular_modifier, arbitrary_modifier])
    |> repeat()

  class =
    choice([
      # Visual Effects (bg-, backdrop-, outline-, divide- prefixes need careful ordering)
      # Backgrounds - more specific before less specific
      bg_attachment,
      bg_clip,
      bg_origin,
      bg_repeat,
      bg_blend,
      gradient_from_pos,
      gradient_via_pos,
      gradient_to_pos,
      gradient_from,
      gradient_via,
      gradient_to,
      # Background color - before bg-* parsers with arbitrary_value
      bg,
      # These have arbitrary_value, must come after bg
      bg_size,
      bg_image,
      bg_position,
      # Backdrop filters
      backdrop_blur,
      backdrop_brightness,
      backdrop_contrast,
      backdrop_grayscale,
      backdrop_hue_rotate,
      backdrop_invert,
      backdrop_opacity,
      backdrop_saturate,
      backdrop_sepia,
      # Filters
      blur,
      brightness,
      contrast,
      drop_shadow,
      hue_rotate,
      invert,
      saturate,
      sepia,
      # Borders & Outlines (table borders before regular borders)
      border_collapse,
      border_spacing_x,
      border_spacing_y,
      border_spacing,
      table_layout,
      caption,
      rounded,
      border_w,
      border_style,
      divide_x,
      divide_y,
      divide_style,
      divide_color,
      outline_style,
      outline_offset,
      outline_w,
      outline_color,
      # Shadows & Effects
      shadow,
      shadow_color,
      opacity,
      # Transforms & Transitions
      scale_x,
      scale_y,
      scale,
      rotate,
      skew_x,
      skew_y,
      translate_x,
      translate_y,
      translate_none,
      transform_origin,
      perspective,
      perspective_origin,
      transition,
      duration,
      ease,
      delay,
      animate,
      # Flexbox & Grid (before display which has "flex" and "grid")
      flex_direction,
      flex_wrap,
      flex,
      justify_items,
      justify_self,
      justify_content,
      align_items,
      align_self,
      align_content,
      place_content,
      place_items,
      place_self,
      gap_x,
      gap_y,
      gap,
      grid_cols,
      grid_rows,
      grid_flow,
      col_start_end,
      col_start,
      col_end,
      row_start_end,
      row_start,
      row_end,
      auto_cols,
      auto_rows,
      # Layout & Positioning
      aspect,
      container,
      columns,
      break_after,
      break_before,
      break_inside,
      box_decoration,
      box,
      sr,
      float,
      clear,
      isolation,
      object_position,
      object_fit,
      position,
      inset_x,
      inset_y,
      inset,
      start,
      end_position,
      top,
      right,
      bottom,
      left,
      visibility,
      z,
      # Typography (text- and font- parsers before others)
      # Note: text_color must come before font_size to handle text-[#hex] correctly
      text_color,
      text_alignment,
      text_wrap,
      font_size,
      font_weight,
      font_family,
      font_smoothing,
      font_style,
      fvn_normal,
      fvn_ordinal,
      fvn_slashed_zero,
      fvn_figure,
      fvn_spacing,
      fvn_fraction,
      tracking,
      line_clamp,
      leading,
      list_image,
      list_style_position,
      list_style_type,
      text_decoration_color,
      text_decoration_thickness,
      text_decoration_style,
      underline_offset,
      text_transform,
      text_overflow,
      indent,
      vertical_align,
      whitespace,
      word_break,
      hyphens,
      content,
      # Interactivity
      scroll_mx,
      scroll_my,
      scroll_ms,
      scroll_me,
      scroll_mt,
      scroll_mr,
      scroll_mb,
      scroll_ml,
      scroll_m,
      scroll_px,
      scroll_py,
      scroll_ps,
      scroll_pe,
      scroll_pt,
      scroll_pr,
      scroll_pb,
      scroll_pl,
      scroll_p,
      scroll_behavior,
      snap_align,
      snap_stop,
      snap_type,
      touch_x,
      touch_y,
      touch_pz,
      touch,
      cursor,
      pointer_events,
      resize,
      user_select,
      will_change,
      # Display
      display,
      # Sizing
      min_w,
      max_w,
      min_h,
      max_h,
      size,
      w,
      h,
      # Overflow
      overflow_x,
      overflow_y,
      overflow,
      # Spacing
      space_x,
      space_y,
      px,
      py,
      ps,
      pe,
      pt,
      pr,
      pb,
      pl,
      p,
      mx,
      my,
      ms,
      me,
      mt,
      mr,
      mb,
      ml,
      m,
      # Colors
      border_color,
      # Other (SVG and effects)
      fill,
      stroke,
      stroke_width,
      grayscale,
      grow,
      mix_blend,
      text_decoration,
      custom
    ])

  defparsec(:class, class)
  defparsec(:modifiers, modifiers)
  defparsec(:arbitrary_color_value, arbitrary_color_value)
end
