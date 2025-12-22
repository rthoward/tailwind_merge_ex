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

  test "color classes" do
    # Background color conflicts
    assert tw("bg-red-500 bg-blue-500") == "bg-blue-500"
    assert tw("bg-transparent bg-current") == "bg-current"
    assert tw("bg-red-500 bg-[#ff0000]") == "bg-[#ff0000]"

    # Text color conflicts
    assert tw("text-gray-900 text-black") == "text-black"
    assert tw("text-red-500 text-[#123456]") == "text-[#123456]"

    # Border color conflicts
    assert tw("border-gray-300 border-blue-500") == "border-blue-500"
    assert tw("border-red-500 border-transparent") == "border-transparent"

    # Different color types don't conflict
    assert tw("bg-red-500 text-blue-500 border-green-500") ==
             "bg-red-500 text-blue-500 border-green-500"
  end

  test "flexbox classes" do
    # Flex value conflicts
    assert tw("flex-1 flex-auto") == "flex-auto"
    assert tw("flex-initial flex-none") == "flex-none"

    # Flex direction conflicts
    assert tw("flex-row flex-col") == "flex-col"
    assert tw("flex-row-reverse flex-col-reverse") == "flex-col-reverse"

    # Flex wrap conflicts
    assert tw("flex-wrap flex-nowrap") == "flex-nowrap"
    assert tw("flex-wrap-reverse flex-wrap") == "flex-wrap"

    # Justify content conflicts
    assert tw("justify-start justify-center") == "justify-center"
    assert tw("justify-between justify-evenly") == "justify-evenly"

    # Align items conflicts
    assert tw("items-start items-center") == "items-center"
    assert tw("items-baseline items-stretch") == "items-stretch"

    # Gap conflicts
    assert tw("gap-4 gap-8") == "gap-8"
    assert tw("gap-4 gap-x-8") == "gap-x-8"
    assert tw("gap-x-4 gap-y-4 gap-8") == "gap-8"

    # Different flex properties don't conflict
    assert tw("flex-row justify-center items-center") ==
             "flex-row justify-center items-center"
  end

  test "grid classes" do
    # Grid columns conflicts
    assert tw("grid-cols-3 grid-cols-4") == "grid-cols-4"
    assert tw("grid-cols-none grid-cols-subgrid") == "grid-cols-subgrid"

    # Grid rows conflicts
    assert tw("grid-rows-3 grid-rows-4") == "grid-rows-4"
    assert tw("grid-rows-none grid-rows-subgrid") == "grid-rows-subgrid"

    # Column span conflicts
    assert tw("col-span-3 col-span-4") == "col-span-4"
    assert tw("col-span-full col-span-auto") == "col-span-auto"

    # Column start/end conflicts
    assert tw("col-start-1 col-start-2") == "col-start-2"
    assert tw("col-end-3 col-end-4") == "col-end-4"

    # Row span conflicts
    assert tw("row-span-3 row-span-4") == "row-span-4"
    assert tw("row-span-full row-span-auto") == "row-span-auto"

    # Row start/end conflicts
    assert tw("row-start-1 row-start-2") == "row-start-2"
    assert tw("row-end-3 row-end-4") == "row-end-4"

    # Grid flow conflicts
    assert tw("grid-flow-row grid-flow-col") == "grid-flow-col"
    assert tw("grid-flow-row-dense grid-flow-col-dense") == "grid-flow-col-dense"

    # Auto cols/rows conflicts
    assert tw("auto-cols-auto auto-cols-min") == "auto-cols-min"
    assert tw("auto-rows-max auto-rows-fr") == "auto-rows-fr"

    # Different grid properties don't conflict
    assert tw("grid-cols-3 grid-rows-4 gap-4") == "grid-cols-3 grid-rows-4 gap-4"
  end

  test "layout & positioning classes" do
    # Position conflicts
    assert tw("static absolute") == "absolute"
    assert tw("fixed relative") == "relative"

    # Inset conflicts (cross-group)
    assert tw("inset-4 inset-x-8") == "inset-x-8"
    assert tw("inset-4 top-8") == "top-8"
    assert tw("top-4 inset-y-8") == "inset-y-8"

    # Individual positioning conflicts
    assert tw("top-4 top-8") == "top-8"
    assert tw("right-4 right-8") == "right-8"
    assert tw("bottom-4 bottom-8") == "bottom-8"
    assert tw("left-4 left-8") == "left-8"

    # Z-index conflicts
    assert tw("z-10 z-20") == "z-20"
    assert tw("z-auto z-50") == "z-50"

    # Float conflicts
    assert tw("float-left float-right") == "float-right"
    assert tw("float-none float-start") == "float-start"

    # Visibility conflicts
    assert tw("visible invisible") == "invisible"
    assert tw("invisible collapse") == "collapse"

    # Aspect ratio conflicts
    assert tw("aspect-auto aspect-square") == "aspect-square"
    assert tw("aspect-video aspect-[4/3]") == "aspect-[4/3]"

    # Object fit/position conflicts
    assert tw("object-contain object-cover") == "object-cover"
    assert tw("object-center object-top") == "object-top"

    # Different positioning properties don't conflict
    assert tw("absolute top-4 left-4 z-10") == "absolute top-4 left-4 z-10"
  end
end
