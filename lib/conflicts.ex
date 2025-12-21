defmodule TailwindMerge.Conflicts do
  @moduledoc """
  Cross-group conflicts: when a class from one group should remove classes from other groups
  Reference: https://github.com/dcastil/tailwind-merge/blob/v2.5.5/src/lib/default-config.ts#L2234-L2340
  """

  @conflicting_groups_config %{
    # Layout
    overflow: [:overflow_x, :overflow_y],
    overflow_x: [:overflow],
    overflow_y: [:overflow],
    overscroll: [:overscroll_x, :overscroll_y],
    overscroll_x: [:overscroll],
    overscroll_y: [:overscroll],
    inset: [:inset_x, :inset_y, :start, :end, :top, :right, :bottom, :left],
    inset_x: [:inset, :right, :left],
    inset_y: [:inset, :top, :bottom],
    start: [:inset],
    end: [:inset],
    top: [:inset, :inset_y],
    right: [:inset, :inset_x],
    bottom: [:inset, :inset_y],
    left: [:inset, :inset_x],

    # Flexbox & Grid
    flex: [:basis, :grow, :shrink],
    basis: [:flex],
    shrink: [:flex],
    gap: [:gap_x, :gap_y],
    gap_x: [:gap],
    gap_y: [:gap],

    # Spacing - Padding
    p: [:px, :py, :ps, :pe, :pt, :pr, :pb, :pl],
    px: [:p, :pr, :pl],
    py: [:p, :pt, :pb],
    ps: [:p],
    pe: [:p],
    pt: [:p, :py],
    pr: [:p, :px],
    pb: [:p, :py],
    pl: [:p, :px],

    # Spacing - Margin
    m: [:mx, :my, :ms, :me, :mt, :mr, :mb, :ml],
    mx: [:m, :mr, :ml],
    my: [:m, :mt, :mb],
    ms: [:m],
    me: [:m],
    mt: [:m, :my],
    mr: [:m, :mx],
    mb: [:m, :my],
    ml: [:m, :mx],

    # Sizing
    size: [:w, :h],
    w: [:size],
    h: [:size],

    # Typography
    font_size: [:leading],
    leading: [:font_size],
    line_clamp: [:display, :overflow],

    # Font Variant Numeric
    fvn_normal: [:fvn_ordinal, :fvn_slashed_zero, :fvn_figure, :fvn_spacing, :fvn_fraction],
    fvn_ordinal: [:fvn_normal],
    fvn_slashed_zero: [:fvn_normal],
    fvn_figure: [:fvn_normal],
    fvn_spacing: [:fvn_normal],
    fvn_fraction: [:fvn_normal],

    # Borders - Radius
    rounded: [
      :rounded_s,
      :rounded_e,
      :rounded_t,
      :rounded_r,
      :rounded_b,
      :rounded_l,
      :rounded_ss,
      :rounded_se,
      :rounded_ee,
      :rounded_es,
      :rounded_tl,
      :rounded_tr,
      :rounded_br,
      :rounded_bl
    ],
    rounded_s: [:rounded, :rounded_ss, :rounded_es],
    rounded_e: [:rounded, :rounded_se, :rounded_ee],
    rounded_t: [:rounded, :rounded_tl, :rounded_tr],
    rounded_r: [:rounded, :rounded_tr, :rounded_br],
    rounded_b: [:rounded, :rounded_br, :rounded_bl],
    rounded_l: [:rounded, :rounded_tl, :rounded_bl],
    rounded_ss: [:rounded, :rounded_s],
    rounded_se: [:rounded, :rounded_e],
    rounded_ee: [:rounded, :rounded_e],
    rounded_es: [:rounded, :rounded_s],
    rounded_tl: [:rounded, :rounded_t, :rounded_l],
    rounded_tr: [:rounded, :rounded_t, :rounded_r],
    rounded_br: [:rounded, :rounded_b, :rounded_r],
    rounded_bl: [:rounded, :rounded_b, :rounded_l],

    # Borders - Width
    border_w: [
      :border_w_x,
      :border_w_y,
      :border_w_s,
      :border_w_e,
      :border_w_t,
      :border_w_r,
      :border_w_b,
      :border_w_l
    ],
    border_w_x: [:border_w, :border_w_r, :border_w_l],
    border_w_y: [:border_w, :border_w_t, :border_w_b],
    border_w_s: [:border_w],
    border_w_e: [:border_w],
    border_w_t: [:border_w, :border_w_y],
    border_w_r: [:border_w, :border_w_x],
    border_w_b: [:border_w, :border_w_y],
    border_w_l: [:border_w, :border_w_x],

    # Borders - Color
    border_color: [
      :border_color_x,
      :border_color_y,
      :border_color_s,
      :border_color_e,
      :border_color_t,
      :border_color_r,
      :border_color_b,
      :border_color_l
    ],
    border_color_x: [:border_color, :border_color_r, :border_color_l],
    border_color_y: [:border_color, :border_color_t, :border_color_b],
    border_color_s: [:border_color],
    border_color_e: [:border_color],
    border_color_t: [:border_color, :border_color_y],
    border_color_r: [:border_color, :border_color_x],
    border_color_b: [:border_color, :border_color_y],
    border_color_l: [:border_color, :border_color_x],

    # Border Spacing
    border_spacing: [:border_spacing_x, :border_spacing_y],
    border_spacing_x: [:border_spacing],
    border_spacing_y: [:border_spacing],

    # Transforms
    translate: [:translate_x, :translate_y, :translate_none],
    translate_x: [:translate, :translate_none],
    translate_y: [:translate, :translate_none],
    translate_z: [:translate_none],
    translate_none: [:translate, :translate_x, :translate_y, :translate_z],

    # Scroll Margin
    scroll_m: [
      :scroll_mx,
      :scroll_my,
      :scroll_ms,
      :scroll_me,
      :scroll_mt,
      :scroll_mr,
      :scroll_mb,
      :scroll_ml
    ],
    scroll_mx: [:scroll_m, :scroll_mr, :scroll_ml],
    scroll_my: [:scroll_m, :scroll_mt, :scroll_mb],
    scroll_ms: [:scroll_m],
    scroll_me: [:scroll_m],
    scroll_mt: [:scroll_m, :scroll_my],
    scroll_mr: [:scroll_m, :scroll_mx],
    scroll_mb: [:scroll_m, :scroll_my],
    scroll_ml: [:scroll_m, :scroll_mx],

    # Scroll Padding
    scroll_p: [
      :scroll_px,
      :scroll_py,
      :scroll_ps,
      :scroll_pe,
      :scroll_pt,
      :scroll_pr,
      :scroll_pb,
      :scroll_pl
    ],
    scroll_px: [:scroll_p, :scroll_pr, :scroll_pl],
    scroll_py: [:scroll_p, :scroll_pt, :scroll_pb],
    scroll_ps: [:scroll_p],
    scroll_pe: [:scroll_p],
    scroll_pt: [:scroll_p, :scroll_py],
    scroll_pr: [:scroll_p, :scroll_px],
    scroll_pb: [:scroll_p, :scroll_py],
    scroll_pl: [:scroll_p, :scroll_px],

    # Touch
    touch: [:touch_x, :touch_y, :touch_pz],
    touch_x: [:touch],
    touch_y: [:touch],
    touch_pz: [:touch]
  }

  @conflicting_groups Map.new(@conflicting_groups_config, fn {k, v} -> {k, MapSet.new(v)} end)

  def groups(group) do
    @conflicting_groups
    |> Map.get(group, [])
    |> MapSet.new()
    |> MapSet.put(group)
  end
end
