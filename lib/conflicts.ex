defmodule TailwindMerge.Conflicts do
  @moduledoc """
  Cross-group conflicts: when a class from one group should remove classes from other groups
  Reference: https://github.com/dcastil/tailwind-merge/blob/v2.5.5/src/lib/default-config.ts#L2234-L2340
  """

  @conflicting_groups %{
    overflow: [:overflow_x, :overflow_y],
    overscroll: [:overscroll_x, :overscroll_y],
    inset: [:inset_x, :inset_y, :start, :end, :top, :right, :bottom, :left],
    inset_x: [:right, :left],
    inset_y: [:top, :bottom],
    flex: [:basis, :grow, :shrink],
    gap: [:gap_x, :gap_y],
    p: [:px, :py, :ps, :pe, :pt, :pr, :pb, :pl],
    px: [:pr, :pl],
    py: [:pt, :pb],
    m: [:mx, :my, :ms, :me, :mt, :mr, :mb, :ml],
    mx: [:mr, :ml],
    my: [:mt, :mb],
    size: [:w, :h],
    font_size: [:leading],
    fvn_normal: [:fvn_ordinal, :fvn_slashed_zero, :fvn_figure, :fvn_spacing, :fvn_fraction],
    fvn_ordinal: [:fvn_normal],
    fvn_slashed_zero: [:fvn_normal],
    fvn_figure: [:fvn_normal],
    fvn_spacing: [:fvn_normal],
    fvn_fraction: [:fvn_normal],
    line_clamp: [:display, :overflow],
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
    rounded_s: [:rounded_ss, :rounded_es],
    rounded_e: [:rounded_se, :rounded_ee],
    rounded_t: [:rounded_tl, :rounded_tr],
    rounded_r: [:rounded_tr, :rounded_br],
    rounded_b: [:rounded_br, :rounded_bl],
    rounded_l: [:rounded_tl, :rounded_bl],
    border_spacing: [:border_spacing_x, :border_spacing_y],
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
    border_w_x: [:border_w_r, :border_w_l],
    border_w_y: [:border_w_t, :border_w_b],
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
    border_color_x: [:border_color_r, :border_color_l],
    border_color_y: [:border_color_t, :border_color_b],
    translate: [:translate_x, :translate_y, :translate_none],
    translate_none: [:translate, :translate_x, :translate_y, :translate_z],
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
    scroll_mx: [:scroll_mr, :scroll_ml],
    scroll_my: [:scroll_mt, :scroll_mb],
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
    scroll_px: [:scroll_pr, :scroll_pl],
    scroll_py: [:scroll_pt, :scroll_pb],
    touch: [:touch_x, :touch_y, :touch_pz],
    touch_x: [:touch],
    touch_y: [:touch],
    touch_pz: [:touch]
  }

  def groups(group), do: [group | @conflicting_groups[group] || []]
end
