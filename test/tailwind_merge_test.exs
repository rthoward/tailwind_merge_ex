defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

  test "tw/1" do
    assert tw("mix-blend-normal mix-blend-multiply") == "mix-blend-multiply"
    assert tw("h-10 h-min") == "h-min"
    assert tw("stroke-black stroke-1") == "stroke-black stroke-1"
    assert tw("stroke-2 stroke-[3]") == "stroke-[3]"
    assert tw("outline-black outline-1") == "outline-black outline-1"
    assert tw("grayscale-0 grayscale-[50%]") == "grayscale-[50%]"
    assert tw("grow grow-[2]") == "grow-[2]"
    assert tw(["grow", [nil, false, [["grow-[2]"]]]]) == "grow-[2]"

    assert tw("!flex block") == "!flex block"
    assert tw("!flex !block") == "!block"
    assert tw("!flex block!") == "block!"

    assert tw("hover:underline underline") == "hover:underline underline"
    assert tw("hover:underline hover:no-underline") == "hover:no-underline"
  end
end
