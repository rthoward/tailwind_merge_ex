defmodule TailwindMerge.Parser do
  import NimbleParsec
  import TailwindMerge.ASCII

  number = integer(min: 1) |> optional(string(".") |> integer(min: 1))
  fraction = integer(min: 1) |> string("/") |> integer(min: 1)
  decimal = integer(min: 1, max: 3) |> string(".") |> integer(min: 1)
  percentage = integer(min: 1, max: 3) |> string("%")
  maybe_negative = optional(string("-"))

  #
  # Units
  #

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

  font_unit =
    choice([
      string("cap"),
      string("ch"),
      string("ex"),
      string("rlh"),
      string("lh")
    ])

  # [s|d|l]?v[h|w|i|b|min|max]
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

  # cq[w|h|i|b|min|max]
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

  tshirt =
    choice([
      string("xs"),
      string("md"),
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
    ])

  any_unit = choice([container_unit, viewport_unit, font_unit, basic_unit])
  length_with_unit = number |> concat(any_unit)

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

  arbitrary_val =
    ascii_char([?[])
    |> optional(
      ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
      |> string(":")
    )
    |> repeat(
      lookahead_not(ascii_char([?]]))
      |> utf8_char([])
    )
    |> ascii_char([?]])

  arbitrary_var =
    ascii_char([?(])
    |> ascii_string(printable(except: ~c"()"), min: 1)
    |> ascii_char([?)])

  arbitrary_property =
    ignore(string("["))
    |> ascii_string(printable(except: ~c"[]:"), min: 1)
    |> ignore(ascii_string([?:], min: 1))
    |> ascii_string(printable(except: ~c"[]"), min: 1)
    |> ignore(string("]"))
    |> post_traverse({:tag_arbitrary_property, []})

  defp tag_arbitrary_property(rest, [_val, prop], context, _position, _offset),
    do: {rest, [{:arbitrary_property, prop}], context}

  scale_position =
    choice([
      string("bottom"),
      string("center"),
      string("left-bottom"),
      string("left-top"),
      string("left"),
      string("right-bottom"),
      string("right-top"),
      string("right"),
      string("top")
  ])

  #
  # Length
  #

  length_variable = string("length:") |> ascii_string(printable(except: ~c"]"), min: 1)

  arbitrary_length =
    ascii_char([?[])
    |> choice([css_function, length_variable, length_with_unit, string("0")])
    |> ascii_char([?]])

  #
  # Common values
  #

  spacing_scale =
    choice([
      string("auto"),
      string("full"),
      string("px"),
      parsec(:decimal),
      integer(min: 1),
      parsec(:fraction),
      parsec(:arbitrary_length),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])

  scale_align_primary_axis =
    choice([
      string("start"),
      string("end-safe"),
      string("end"),
      string("center-safe"),
      string("center"),
      string("between"),
      string("around"),
      string("evenly"),
      string("stretch"),
      string("baseline")
    ])

  scale_align_secondary_axis =
    choice([
      string("center-safe"),
      string("end-safe"),
      string("start"),
      string("end"),
      string("center"),
      string("stretch")
    ])

  sizing_scale =
    choice([
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
      string("screen"),
      string("min"),
      string("max"),
      string("fit"),
      string("lh"),
      string("auto"),
      string("full"),
      string("px"),
      parsec(:decimal),
      integer(min: 1),
      string("0"),
      parsec(:fraction),
      parsec(:arbitrary_length),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])

  #
  # Color
  #

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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    )

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


  hex_color = string("#") |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 3, max: 8)

  color_value =
    choice([
      string("transparent"),
      string("current"),
      string("inherit"),
      string("color:0"),
      color_function,
      hex_color,
      named_color
    ])


  arbitrary_color_val =
    ascii_char([?[])
    |> parsec(:color_value)
    |> ascii_char([?]])

  bg_color =
    string("bg-")
    |> parsec(:color_value)
    |> tag(:bg_color)

  text_color =
    string("text-")
    |> choice([parsec(:color_value), parsec(:arbitrary_color_val), parsec(:arbitrary_var)])
    |> tag(:text_color)

  border_color =
    string("border-")
    |> parsec(:color_value)
    |> tag(:border_color)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:skew_y)

  translate_x =
    string("translate-x-")
    |> parsec(:spacing_scale)
    |> tag(:translate_x)

  translate_y =
    string("translate-y-")
    |> parsec(:spacing_scale)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:transform_origin)

  perspective =
    string("perspective-")
    |> choice([
      string("none"),
      parsec(:arbitrary_length),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:perspective_origin)

  #
  # Animation
  #

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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:duration)

  ease =
    string("ease-")
    |> choice([
      string("linear"),
      string("in-out"),
      string("in"),
      string("out"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:animate)

  #
  # Tables
  #

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
    |> parsec(:spacing_scale)
    |> tag(:border_spacing)

  border_spacing_x =
    string("border-spacing-x-")
    |> parsec(:spacing_scale)
    |> tag(:border_spacing_x)

  border_spacing_y =
    string("border-spacing-y-")
    |> parsec(:spacing_scale)
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

  #
  # Interactivity
  #

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:cursor)

  pointer_events =
    string("pointer-events-")
    |> choice([string("none"), string("auto")])
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
    |> choice([string("auto"), string("smooth")])
    |> eos()
    |> tag(:scroll_behavior)

  scroll_m = string("scroll-m-") |> parsec(:spacing_scale) |> tag(:scroll_m)
  scroll_mx = string("scroll-mx-") |> parsec(:spacing_scale) |> tag(:scroll_mx)
  scroll_my = string("scroll-my-") |> parsec(:spacing_scale) |> tag(:scroll_my)
  scroll_ms = string("scroll-ms-") |> parsec(:spacing_scale) |> tag(:scroll_ms)
  scroll_me = string("scroll-me-") |> parsec(:spacing_scale) |> tag(:scroll_me)
  scroll_mt = string("scroll-mt-") |> parsec(:spacing_scale) |> tag(:scroll_mt)
  scroll_mr = string("scroll-mr-") |> parsec(:spacing_scale) |> tag(:scroll_mr)
  scroll_mb = string("scroll-mb-") |> parsec(:spacing_scale) |> tag(:scroll_mb)
  scroll_ml = string("scroll-ml-") |> parsec(:spacing_scale) |> tag(:scroll_ml)
  scroll_p = string("scroll-p-") |> parsec(:spacing_scale) |> tag(:scroll_p)
  scroll_px = string("scroll-px-") |> parsec(:spacing_scale) |> tag(:scroll_px)
  scroll_py = string("scroll-py-") |> parsec(:spacing_scale) |> tag(:scroll_py)
  scroll_ps = string("scroll-ps-") |> parsec(:spacing_scale) |> tag(:scroll_ps)
  scroll_pe = string("scroll-pe-") |> parsec(:spacing_scale) |> tag(:scroll_pe)
  scroll_pt = string("scroll-pt-") |> parsec(:spacing_scale) |> tag(:scroll_pt)
  scroll_pr = string("scroll-pr-") |> parsec(:spacing_scale) |> tag(:scroll_pr)
  scroll_pb = string("scroll-pb-") |> parsec(:spacing_scale) |> tag(:scroll_pb)
  scroll_pl = string("scroll-pl-") |> parsec(:spacing_scale) |> tag(:scroll_pl)

  snap_align =
    string("snap-")
    |> parsec(:scale_align_secondary_axis)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:will_change)

  # SVG
  fill = string("fill-") |> choice([string("none"), parsec(:color_value)]) |> tag(:fill)

  #
  # Visual effects
  #

  bg_attachment =
    string("bg-")
    |> choice([string("fixed"), string("local"), string("scroll")])
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
      parsec(:scale_position),
      labelled_var(~w(position percentage)),
      labelled_val(~w(position percentage)),
      string("position-") |> choice([parsec(:arbitrary_var), parsec(:arbitrary_val)])
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
      labelled_val(~w(length size bg-size)),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:bg_image)

  gradient_from_pos =
    string("from-")
    |> choice([percentage, parsec(:arbitrary_val)])
    |> tag(:gradient_from_pos)

  gradient_via_pos =
    string("via-")
    |> choice([percentage, parsec(:arbitrary_val)])
    |> tag(:gradient_via_pos)

  gradient_to_pos =
    string("to-")
    |> choice([percentage, parsec(:arbitrary_val)])
    |> tag(:gradient_to_pos)

  gradient_from = string("from-") |> parsec(:color_value) |> tag(:gradient_from)
  gradient_via = string("via-") |> parsec(:color_value) |> tag(:gradient_via)
  gradient_to = string("to-") |> parsec(:color_value) |> tag(:gradient_to)

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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
    |> parsec(:color_value)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:outline_offset)

  outline_color =
    string("outline-")
    |> parsec(:color_value)
    |> tag(:outline_color)

  # Effects
  shadow =
    string("shadow")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("none"),
        string("inner"),
        parsec(:tshirt),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    ])
    |> tag(:shadow)

  shadow_color =
    string("shadow-")
    |> parsec(:color_value)
    |> tag(:shadow_color)

  opacity =
    string("opacity-")
    |> choice([
      integer(min: 1, max: 3),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    ])
    |> tag(:blur)

  brightness =
    string("brightness-")
    |> choice([
      integer(min: 1, max: 3),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:hue_rotate)

  invert =
    string("invert")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:saturate)

  sepia =
    string("sepia")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:backdrop_contrast)

  backdrop_grayscale =
    string("backdrop-grayscale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:backdrop_hue_rotate)

  backdrop_invert =
    string("backdrop-invert")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    ])
    |> tag(:backdrop_invert)

  backdrop_opacity =
    string("backdrop-opacity-")
    |> choice([
      integer(min: 1, max: 3),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:backdrop_saturate)

  backdrop_sepia =
    string("backdrop-sepia")
    |> choice([
      eos(),
      string("-")
      |> choice([
        string("0"),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    ])
    |> tag(:backdrop_sepia)

  #
  # Layout and positioning
  #

  aspect =
    string("aspect-")
    |> choice([
      string("auto"),
      string("square"),
      string("video"),
      parsec(:fraction),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:aspect)

  container =
    string("container")
    |> eos()
    |> tag(:container)

  columns =
    string("columns-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_length),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:columns)

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

  break_inside =
    string("break-inside-")
    |> choice([
      string("auto"),
      string("avoid"),
      string("avoid-page"),
      string("avoid-column")
    ])
    |> tag(:break_inside)

  box_decoration =
    string("box-decoration-")
    |> choice([
      string("slice"),
      string("clone")
    ])
    |> tag(:box_decoration)

  box =
    string("box-")
    |> choice([string("border"), string("content")])
    |> tag(:box)

  sr =
    choice([string("sr-only"), string("not-sr-only")])
    |> eos()
    |> tag(:sr)

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
      parsec(:scale_position),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:object_position)

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

  inset =
    string("inset-")
    |> parsec(:spacing_scale)
    |> tag(:inset)

  inset_x =
    string("inset-x-")
    |> parsec(:spacing_scale)
    |> tag(:inset_x)

  inset_y =
    string("inset-y-")
    |> parsec(:spacing_scale)
    |> tag(:inset_y)

  start =
    parsec(:maybe_negative)
    |> string("start-")
    |> parsec(:spacing_scale)
    |> tag(:start)

  end_position =
    parsec(:maybe_negative)
    |> string("end-")
    |> parsec(:spacing_scale)
    |> tag(:end)

  top =
    parsec(:maybe_negative)
    |> string("top-")
    |> parsec(:spacing_scale)
    |> tag(:top)

  right =
    parsec(:maybe_negative)
    |> string("right-")
    |> parsec(:spacing_scale)
    |> tag(:right)

  bottom =
    parsec(:maybe_negative)
    |> string("bottom-")
    |> parsec(:spacing_scale)
    |> tag(:bottom)

  left =
    parsec(:maybe_negative)
    |> string("left-")
    |> parsec(:spacing_scale)
    |> tag(:left)

  visibility =
    choice([
      string("visible"),
      string("invisible"),
      string("collapse")
    ])
    |> eos()
    |> tag(:visibility)

  z =
    string("z-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 50),
      string("0"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:z)

  #
  # Typography
  #

  text_size =
    string("text-")
    |> choice([
      parsec(:tshirt),
      parsec(:arbitrary_length),
      parsec(:arbitrary_var)
    ])
    |> tag(:text_size)

  font_smoothing =
    choice([
      string("antialiased"),
      string("subpixel-antialiased")
    ])
    |> eos()
    |> tag(:font_smoothing)

  font_style =
    choice([
      string("not-italic"),
      string("italic")
    ])
    |> eos()
    |> tag(:font_style)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:font_weight)

  font_family =
    string("font-")
    |> choice([
      string("sans"),
      string("serif"),
      string("mono"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:font_family)

  fvn_normal =
    string("normal-nums")
    |> eos()
    |> tag(:fvn_normal)

  # Font variant numeric - ordinal
  fvn_ordinal =
    string("ordinal")
    |> eos()
    |> tag(:fvn_ordinal)

  fvn_slashed_zero =
    string("slashed-zero")
    |> eos()
    |> tag(:fvn_slashed_zero)

  fvn_figure =
    choice([
      string("lining-nums"),
      string("oldstyle-nums")
    ])
    |> eos()
    |> tag(:fvn_figure)

  fvn_spacing =
    choice([
      string("proportional-nums"),
      string("tabular-nums")
    ])
    |> eos()
    |> tag(:fvn_spacing)

  fvn_fraction =
    choice([
      string("diagonal-fractions"),
      string("stacked-fractions")
    ])
    |> eos()
    |> tag(:fvn_fraction)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:tracking)

  line_clamp =
    string("line-clamp-")
    |> choice([
      string("none"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:line_clamp)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:leading)

  list_image =
    string("list-image-")
    |> choice([
      string("none"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:list_image)

  list_style_position =
    string("list-")
    |> choice([
      string("inside"),
      string("outside")
    ])
    |> tag(:list_style_position)

  list_style_type =
    string("list-")
    |> choice([
      string("none"),
      string("disc"),
      string("decimal")
    ])
    |> tag(:list_style_type)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:text_decoration_thickness)

  text_decoration_color =
    string("decoration-")
    |> parsec(:color_value)
    |> tag(:text_decoration_color)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:underline_offset)

  text_transform =
    choice([
      string("uppercase"),
      string("lowercase"),
      string("capitalize"),
      string("normal-case")
    ])
    |> eos()
    |> tag(:text_transform)

  text_overflow =
    choice([
      string("truncate"),
      string("text-ellipsis"),
      string("text-clip")
    ])
    |> eos()
    |> tag(:text_overflow)

  text_wrap =
    string("text-")
    |> choice([
      string("wrap"),
      string("nowrap"),
      string("balance"),
      string("pretty")
    ])
    |> tag(:text_wrap)

  indent =
    string("indent-")
    |> parsec(:spacing_scale)
    |> tag(:indent)

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
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:vertical_align)

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

  word_break =
    string("break-")
    |> choice([
      string("normal"),
      string("words"),
      string("all"),
      string("keep")
    ])
    |> tag(:word_break)

  hyphens =
    string("hyphens-")
    |> choice([
      string("none"),
      string("manual"),
      string("auto")
    ])
    |> tag(:hyphens)

  content =
    string("content-")
    |> choice([
      string("none"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:content)

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

  #
  # Flexbox and grid
  #

  flex =
    string("flex-")
    |> choice([
      string("1"),
      string("auto"),
      string("initial"),
      string("none"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:flex)

  flex_direction =
    string("flex-")
    |> choice([
      string("row-reverse"),
      string("col-reverse"),
      string("row"),
      string("col")
    ])
    |> tag(:flex_direction)

  flex_wrap =
    string("flex-")
    |> choice([string("wrap-reverse"), string("nowrap"), string("wrap")])
    |> tag(:flex_wrap)

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

  justify_items =
    string("justify-items-")
    |> parsec(:scale_align_secondary_axis)
    |> tag(:justify_items)

  justify_self =
    string("justify-self-")
    |> parsec(:scale_align_secondary_axis)
    |> tag(:justify_self)

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

  align_items =
    string("items-")
    |> choice([
    parsec(:scale_align_secondary_axis),
      string("baseline-last"),
      string("baseline")
    ])
    |> tag(:align_items)

  align_self =
    string("self-")
    |> choice([
      parsec(:scale_align_secondary_axis),
      string("baseline-last"),
      string("baseline"),
      string("auto"),
    ])
    |> tag(:align_self)

  place_content =
    string("place-content-")
    |> parsec(:scale_align_primary_axis)
    |> tag(:place_content)

  place_items =
    string("place-items-")
    |> choice([string("baseline"), parsec(:scale_align_secondary_axis)])
    |> tag(:place_items)

  place_self =
    string("place-self-")
    |> choice([string("auto"), parsec(:scale_align_secondary_axis)])
    |> tag(:place_self)

  gap =
    string("gap-")
    |> parsec(:spacing_scale)
    |> tag(:gap)

  gap_x =
    string("gap-x-")
    |> parsec(:spacing_scale)
    |> tag(:gap_x)

  gap_y =
    string("gap-y-")
    |> parsec(:spacing_scale)
    |> tag(:gap_y)

  basis =
    string("basis-")
    |> concat(spacing_scale)
    |> tag(:basis)

  grid_cols =
    string("grid-cols-")
    |> choice([
      string("subgrid"),
      string("none"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:grid_cols)

  col_start_end =
    string("col-span-")
    |> choice([
      string("full"),
      string("auto"),
      integer(min: 1, max: 12),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:col_start_end)

  col_start =
    string("col-start-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 13),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:col_start)

  col_end =
    string("col-end-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 13),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:col_end)

  grid_rows =
    string("grid-rows-")
    |> choice([
      string("subgrid"),
      string("none"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:grid_rows)

  row_start_end =
    string("row-span-")
    |> choice([
      string("full"),
      string("auto"),
      integer(min: 1, max: 6),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:row_start_end)

  row_start =
    string("row-start-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 7),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:row_start)

  row_end =
    string("row-end-")
    |> choice([
      string("auto"),
      integer(min: 1, max: 7),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:row_end)

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

  auto_cols =
    string("auto-cols-")
    |> choice([
      string("auto"),
      string("min"),
      string("max"),
      string("fr"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:auto_cols)

  auto_rows =
    string("auto-rows-")
    |> choice([
      string("auto"),
      string("min"),
      string("max"),
      string("fr"),
      parsec(:arbitrary_val),
      parsec(:arbitrary_var)
    ])
    |> tag(:auto_rows)

  h =
    string("h-")
    |> parsec(:sizing_scale)
    |> tag(:height)

  stroke_width =
    string("stroke-")
    |> choice([
      integer(min: 1),
      parsec(:arbitrary_length),
      parsec(:arbitrary_val)
    ])
    |> tag(:stroke_width)

  stroke =
    string("stroke-")
    |> choice([string("none"), parsec(:arbitrary_color_val)])
    |> tag(:stroke)

  grayscale =
    string("grayscale")
    |> choice([
      eos(),
      string("-")
      |> choice([
        integer(min: 1),
        parsec(:arbitrary_length),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
    ])
    |> tag(:grayscale)

  grow =
    string("grow")
    |> choice([
      eos(),
      string("-")
      |> choice([
        integer(min: 1),
        parsec(:arbitrary_length),
        parsec(:arbitrary_val),
        parsec(:arbitrary_var)
      ])
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

  text_shadow_color =
    string("text-shadow-")
    |> parsec(:color_value)
    |> tag(:text_shadow_color)

  text_shadow_size =
    string("text-shadow-")
    |> choice([string("none"), parsec(:tshirt)])
    |> tag(:text_shadow_size)

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

  overflow_x =
    string("overflow-x-")
    |> concat(overflow_value)
    |> tag(:overflow_x)

  overflow_y =
    string("overflow-y-")
    |> concat(overflow_value)
    |> tag(:overflow_y)

  #
  # Spacing
  #

  p =
    parsec(:maybe_negative)
    |> string("p-")
    |> parsec(:spacing_scale)
    |> tag(:p)

  px =
    parsec(:maybe_negative)
    |> string("px-")
    |> parsec(:spacing_scale)
    |> tag(:px)

  py =
    parsec(:maybe_negative)
    |> string("py-")
    |> parsec(:spacing_scale)
    |> tag(:py)

  ps =
    parsec(:maybe_negative)
    |> string("ps-")
    |> parsec(:spacing_scale)
    |> tag(:ps)

  pe =
    parsec(:maybe_negative)
    |> string("pe-")
    |> parsec(:spacing_scale)
    |> tag(:pe)

  pt =
    parsec(:maybe_negative)
    |> string("pt-")
    |> parsec(:spacing_scale)
    |> tag(:pt)

  pr =
    parsec(:maybe_negative)
    |> string("pr-")
    |> parsec(:spacing_scale)
    |> tag(:pr)

  pb =
    parsec(:maybe_negative)
    |> string("pb-")
    |> parsec(:spacing_scale)
    |> tag(:pb)

  pl =
    parsec(:maybe_negative)
    |> string("pl-")
    |> parsec(:spacing_scale)
    |> tag(:pl)

  m =
    parsec(:maybe_negative)
    |> string("m-")
    |> parsec(:spacing_scale)
    |> tag(:m)

  mx =
    parsec(:maybe_negative)
    |> string("mx-")
    |> parsec(:spacing_scale)
    |> tag(:mx)

  my =
    parsec(:maybe_negative)
    |> string("my-")
    |> parsec(:spacing_scale)
    |> tag(:my)

  ms =
    parsec(:maybe_negative)
    |> string("ms-")
    |> parsec(:spacing_scale)
    |> tag(:ms)

  me =
    parsec(:maybe_negative)
    |> string("me-")
    |> parsec(:spacing_scale)
    |> tag(:me)

  mt =
    parsec(:maybe_negative)
    |> string("mt-")
    |> parsec(:spacing_scale)
    |> tag(:mt)

  mr =
    parsec(:maybe_negative)
    |> string("mr-")
    |> parsec(:spacing_scale)
    |> tag(:mr)

  mb =
    parsec(:maybe_negative)
    |> string("mb-")
    |> parsec(:spacing_scale)
    |> tag(:mb)

  ml =
    parsec(:maybe_negative)
    |>string("ml-")
    |> parsec(:spacing_scale)
    |> tag(:ml)

  space_x =
    string("space-x-")
    |> parsec(:spacing_scale)
    |> tag(:space_x)

  space_y =
    string("space-y-")
    |> parsec(:spacing_scale)
    |> tag(:space_y)

  #
  # Sizing
  #

  w =
    string("w-")
    |> parsec(:sizing_scale)
    |> tag(:w)

  min_w =
    string("min-w-")
    |> parsec(:sizing_scale)
    |> tag(:min_w)

  max_w =
    string("max-w-")
    |> parsec(:sizing_scale)
    |> tag(:max_w)

  min_h =
    string("min-h-")
    |> parsec(:sizing_scale)
    |> tag(:min_h)

  max_h =
    string("max-h-")
    |> parsec(:sizing_scale)
    |> tag(:max_h)

  size =
    string("size-")
    |> parsec(:sizing_scale)
    |> tag(:size)

  wrap =
    string("wrap-")
    |> choice([
      string("break-word"),
      string("anywhere"),
      string("normal")
    ])
    |> tag(:wrap)

  custom = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?/], min: 1)

  regular_modifier =
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-], min: 1)
    |> ignore(ascii_char([?:]))
    |> unwrap_and_tag(:regular_modifier)

  arbitrary_modifier =
    ignore(ascii_char([?[]))
    |> ascii_string(printable(except: ?]), min: 1)
    |> ignore(repeat(ascii_char([?]])))
    |> ignore(ascii_char([?:]))
    |> unwrap_and_tag(:arbitrary_modifier)

  modifiers = choice([arbitrary_modifier, regular_modifier]) |> repeat()

  class =
    choice([
      arbitrary_property,
      bg_attachment, bg_clip, bg_origin, bg_repeat, bg_blend,
      gradient_from_pos, gradient_via_pos, gradient_to_pos, gradient_from, gradient_via, gradient_to,
      bg_position, bg_size, bg_image, bg_color,
      backdrop_blur,
      backdrop_brightness,
      backdrop_contrast,
      backdrop_grayscale,
      backdrop_hue_rotate,
      backdrop_invert,
      backdrop_opacity,
      backdrop_saturate,
      backdrop_sepia,
      blur,
      brightness,
      contrast,
      drop_shadow,
      hue_rotate,
      invert,
      saturate,
      sepia,
      border_collapse, border_spacing_x, border_spacing_y, border_spacing,
      table_layout,
      caption,
      rounded,
      border_w,
      border_style,
      divide_x, divide_y, divide_style, divide_color,
      outline_style, outline_offset, outline_w, outline_color,
      shadow, shadow_color,
      opacity,
      scale_x, scale_y, scale, rotate, skew_x, skew_y, translate_x, translate_y, translate_none, transform_origin,
      perspective, perspective_origin,
      transition, duration, ease, delay, animate,
      flex_direction, flex_wrap, flex, basis,
      justify_items, justify_self, justify_content,
      align_items, align_self, align_content,
      place_content, place_items, place_self,
      gap_x, gap_y, gap,
      grid_cols, grid_rows, grid_flow,
      col_start_end, col_start, col_end,
      row_start_end, row_start, row_end,
      auto_cols, auto_rows,
      aspect,
      container,
      columns,
      break_after, break_before,
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
      inset_x, inset_y, inset,
      start,
      end_position,
      top, right, bottom, left,
      visibility,
      z,
      text_shadow_size, text_shadow_color,
      text_color, text_alignment, text_wrap, text_size,
      font_weight, font_family, font_smoothing, font_style,
      fvn_normal, fvn_ordinal, fvn_slashed_zero, fvn_figure, fvn_spacing, fvn_fraction,
      tracking,
      line_clamp,
      leading,
      list_image, list_style_position, list_style_type,
      text_decoration, text_decoration_color, text_decoration_thickness, text_decoration_style,
      underline_offset,
      text_transform,
      text_overflow,
      indent,
      vertical_align,
      whitespace,
      word_break,
      hyphens,
      content,
      scroll_mx, scroll_my, scroll_ms, scroll_me, scroll_mt, scroll_mr, scroll_mb, scroll_ml, scroll_m,
      scroll_px, scroll_py, scroll_ps, scroll_pe, scroll_pt, scroll_pr, scroll_pb, scroll_pl, scroll_p,
      scroll_behavior,
      snap_align, snap_stop, snap_type,
      touch_x, touch_y, touch_pz, touch,
      cursor,
      pointer_events,
      resize,
      user_select,
      will_change,
      display,
      min_w, max_w, min_h, max_h, size, w, h,
      overflow_x, overflow_y, overflow,
      space_x, space_y,
      px, py, ps, pe, pt, pr, pb, pl, p,
      mx, my, ms, me, mt, mr, mb, ml, m,
      border_color,
      fill,
      stroke, stroke_width,
      grayscale,
      grow,
      mix_blend,
      wrap,
      custom
    ])

  defcombinatorp :decimal, decimal
  defcombinatorp :fraction, fraction
  defcombinatorp :number, number

  defcombinatorp :arbitrary_color_val, arbitrary_color_val
  defcombinatorp :arbitrary_length, arbitrary_length
  defcombinatorp :arbitrary_val, arbitrary_val
  defcombinatorp :arbitrary_var, arbitrary_var
  defcombinatorp :color_function, color_function
  defcombinatorp :color_value, color_value
  defcombinatorp :css_function, css_function
  defcombinatorp :scale_position, scale_position
  defcombinatorp :maybe_negative, maybe_negative
  defcombinatorp :scale_align_primary_axis, scale_align_primary_axis
  defcombinatorp :scale_align_secondary_axis, scale_align_secondary_axis
  defcombinatorp :sizing_scale, sizing_scale
  defcombinatorp :spacing_scale, spacing_scale
  defcombinatorp :tshirt, tshirt

  defparsec :class, class
  defparsec :modifiers, modifiers
end
