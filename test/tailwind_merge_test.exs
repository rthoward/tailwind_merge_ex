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

  test "cross-group conflicts" do
    # overflow conflicts with overflow-x and overflow-y
    assert tw("overflow-auto overflow-x-hidden") == "overflow-x-hidden"
    assert tw("overflow-x-auto overflow-hidden") == "overflow-hidden"
  end

  test "spacing classes" do
    # Padding conflicts
    assert tw("p-4 p-8") == "p-8"
    assert tw("p-4 px-8") == "px-8"
    assert tw("p-4 pt-8") == "pt-8"
    assert tw("px-4 pr-8") == "pr-8"
    assert tw("py-4 pt-8") == "pt-8"
    assert tw("pt-4 pb-4 p-8") == "p-8"

    # Margin conflicts
    assert tw("m-4 m-8") == "m-8"
    assert tw("m-4 mx-8") == "mx-8"
    assert tw("m-4 mt-8") == "mt-8"
    assert tw("mx-4 mr-8") == "mr-8"
    assert tw("my-4 mt-8") == "mt-8"
    assert tw("mt-4 mb-4 m-8") == "m-8"

    # Arbitrary values
    assert tw("p-4 p-[10px]") == "p-[10px]"
    assert tw("m-4 m-[2rem]") == "m-[2rem]"
  end
end
