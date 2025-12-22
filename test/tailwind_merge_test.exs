defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

  # ========== Original Tests (keeping for now) ==========

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

  # ========== Ported Tests from Reference Implementation ==========

  describe "important-modifier.test.ts" do
    test "merges tailwind classes with important modifier correctly" do
      # Postfix important (modern Tailwind v4 syntax)
      assert tw("font-medium! font-bold!") == "font-bold!"
      assert tw("font-medium! font-bold! font-thin") == "font-bold! font-thin"
      # assert tw("right-2! -inset-x-px!") == "-inset-x-px!"  # TODO: negative values
      assert tw("focus:inline! focus:block!") == "focus:block!"

      # assert tw("[--my-var:20px]! [--my-var:30px]!") == "[--my-var:30px]!"  # TODO: arbitrary properties

      # Prefix important (Tailwind v3 legacy syntax)
      assert tw("font-medium! !font-bold") == "!font-bold"
      assert tw("!font-medium !font-bold") == "!font-bold"
      assert tw("!font-medium !font-bold font-thin") == "!font-bold font-thin"
      # assert tw("!right-2 !-inset-x-px") == "!-inset-x-px"  # TODO: negative values
      assert tw("focus:!inline focus:!block") == "focus:!block"

      # assert tw("![--my-var:20px] ![--my-var:30px]") == "![--my-var:30px]"  # TODO: arbitrary properties
    end
  end

  describe "conflicts-across-class-groups.test.ts" do
    test "handles conflicts across class groups correctly" do
      assert tw("inset-1 inset-x-1") == "inset-1 inset-x-1"
      assert tw("inset-x-1 inset-1") == "inset-1"
      assert tw("inset-x-1 left-1 inset-1") == "inset-1"
      assert tw("inset-x-1 inset-1 left-1") == "inset-1 left-1"
      assert tw("inset-x-1 right-1 inset-1") == "inset-1"
      assert tw("inset-x-1 right-1 inset-x-1") == "inset-x-1"
      assert tw("inset-x-1 right-1 inset-y-1") == "inset-x-1 right-1 inset-y-1"
      assert tw("right-1 inset-x-1 inset-y-1") == "inset-x-1 inset-y-1"
      assert tw("inset-x-1 hover:left-1 inset-1") == "hover:left-1 inset-1"
    end

    test "ring and shadow classes do not create conflict" do
      assert tw("ring shadow") == "ring shadow"
      assert tw("ring-2 shadow-md") == "ring-2 shadow-md"
      assert tw("shadow ring") == "shadow ring"
      assert tw("shadow-md ring-2") == "shadow-md ring-2"
    end

    test "touch classes do create conflicts correctly" do
      assert tw("touch-pan-x touch-pan-right") == "touch-pan-right"
      assert tw("touch-none touch-pan-x") == "touch-pan-x"
      assert tw("touch-pan-x touch-none") == "touch-none"

      assert tw("touch-pan-x touch-pan-y touch-pinch-zoom") ==
               "touch-pan-x touch-pan-y touch-pinch-zoom"

      assert tw("touch-manipulation touch-pan-x touch-pan-y touch-pinch-zoom") ==
               "touch-pan-x touch-pan-y touch-pinch-zoom"

      assert tw("touch-pan-x touch-pan-y touch-pinch-zoom touch-auto") == "touch-auto"
    end

    test "line-clamp classes do create conflicts correctly" do
      assert tw("overflow-auto inline line-clamp-1") == "line-clamp-1"
      assert tw("line-clamp-1 overflow-auto inline") == "line-clamp-1 overflow-auto inline"
    end
  end

  describe "class-group-conflicts.test.ts" do
    test "merges classes from same group correctly" do
      assert tw("overflow-x-auto overflow-x-hidden") == "overflow-x-hidden"
      # assert tw("basis-full basis-auto") == "basis-auto"  # TODO: basis not implemented
      assert tw("w-full w-fit") == "w-fit"
      assert tw("overflow-x-auto overflow-x-hidden overflow-x-scroll") == "overflow-x-scroll"

      assert tw("overflow-x-auto hover:overflow-x-hidden overflow-x-scroll") ==
               "hover:overflow-x-hidden overflow-x-scroll"

      assert tw("overflow-x-auto hover:overflow-x-hidden hover:overflow-x-auto overflow-x-scroll") ==
               "hover:overflow-x-auto overflow-x-scroll"

      assert tw("col-span-1 col-span-full") == "col-span-full"

      # assert tw("gap-2 gap-px basis-px basis-3") == "gap-px basis-3"  # TODO: basis not implemented
    end

    test "merges classes from Font Variant Numeric section correctly" do
      assert tw("lining-nums tabular-nums diagonal-fractions") ==
               "lining-nums tabular-nums diagonal-fractions"

      assert tw("normal-nums tabular-nums diagonal-fractions") ==
               "tabular-nums diagonal-fractions"

      assert tw("tabular-nums diagonal-fractions normal-nums") == "normal-nums"
      assert tw("tabular-nums proportional-nums") == "proportional-nums"
    end
  end

  describe "non-conflicting-classes.test.ts" do
    test "merges non-conflicting classes correctly" do
      # assert tw("border-t border-white/10") == "border-t border-white/10"  # TODO: opacity modifiers
      assert tw("border-t border-white") == "border-t border-white"
      # assert tw("text-3.5xl text-black") == "text-3.5xl text-black"  # TODO: fractional sizes
    end
  end

  describe "non-tailwind-classes.test.ts" do
    test "does not alter non-tailwind classes" do
      assert tw("non-tailwind-class inline block") == "non-tailwind-class block"
      assert tw("inline block inline-1") == "block inline-1"
      assert tw("inline block i-inline") == "block i-inline"
      assert tw("focus:inline focus:block focus:inline-1") == "focus:block focus:inline-1"
    end
  end

  describe "standalone-classes.test.ts" do
    test "merges standalone classes from same group correctly" do
      assert tw("inline block") == "block"
      assert tw("hover:block hover:inline") == "hover:inline"
      assert tw("hover:block hover:block") == "hover:block"

      assert tw("inline hover:inline focus:inline hover:block hover:focus:block") ==
               "inline focus:inline hover:block hover:focus:block"

      assert tw("underline line-through") == "line-through"
      assert tw("line-through no-underline") == "no-underline"
    end
  end

  describe "colors.test.ts" do
    test "handles color conflicts properly" do
      assert tw("bg-grey-5 bg-hotpink") == "bg-hotpink"
      assert tw("hover:bg-grey-5 hover:bg-hotpink") == "hover:bg-hotpink"

      assert tw("stroke-[hsl(350_80%_0%)] stroke-[10px]") ==
               "stroke-[hsl(350_80%_0%)] stroke-[10px]"
    end
  end

  describe "modifiers.test.ts" do
    test "conflicts across prefix modifiers" do
      assert tw("hover:block hover:inline") == "hover:inline"
      assert tw("hover:block hover:focus:inline") == "hover:block hover:focus:inline"

      assert tw("hover:block hover:focus:inline focus:hover:inline") ==
               "hover:block focus:hover:inline"

      assert tw("focus-within:inline focus-within:block") == "focus-within:block"
    end

    # TODO: postfix modifiers like text-lg/7 not implemented yet
    # TODO: sorts modifiers correctly tests
  end

  describe "arbitrary-values.test.ts" do
    test "handles simple conflicts with arbitrary values correctly" do
      assert tw("m-[2px] m-[10px]") == "m-[10px]"

      assert tw(
               "m-[2px] m-[11svmin] m-[12in] m-[13lvi] m-[14vb] m-[15vmax] m-[16mm] m-[17%] m-[18em] m-[19px] m-[10dvh]"
             ) == "m-[10dvh]"

      assert tw("h-[10px] h-[11cqw] h-[12cqh] h-[13cqi] h-[14cqb] h-[15cqmin] h-[16cqmax]") ==
               "h-[16cqmax]"

      assert tw("z-20 z-[99]") == "z-[99]"
      assert tw("my-[2px] m-[10rem]") == "m-[10rem]"
      assert tw("cursor-pointer cursor-[grab]") == "cursor-[grab]"

      assert tw("m-[2px] m-[calc(100%-var(--arbitrary))]") ==
               "m-[calc(100%-var(--arbitrary))]"

      assert tw("m-[2px] m-[length:var(--mystery-var)]") == "m-[length:var(--mystery-var)]"
      assert tw("opacity-10 opacity-[0.025]") == "opacity-[0.025]"
      assert tw("scale-75 scale-[1.7]") == "scale-[1.7]"
      assert tw("brightness-90 brightness-[1.75]") == "brightness-[1.75]"

      # Handling of value `0`
      assert tw("min-h-[0.5px] min-h-[0]") == "min-h-[0]"
      assert tw("text-[0.5px] text-[color:0]") == "text-[0.5px] text-[color:0]"
      # TODO: arbitrary variables with () syntax not implemented
      # assert tw("text-[0.5px] text-(--my-0)") == "text-[0.5px] text-(--my-0)"
    end

    test "handles arbitrary length conflicts with labels and modifiers correctly" do
      assert tw("hover:m-[2px] hover:m-[length:var(--c)]") == "hover:m-[length:var(--c)]"

      assert tw("hover:focus:m-[2px] focus:hover:m-[length:var(--c)]") ==
               "focus:hover:m-[length:var(--c)]"

      # TODO: border-b, border-t, border-r, border-l parsers needed
      # assert tw("border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]") == ...
    end

    test "handles complex arbitrary value conflicts correctly" do
      assert tw("grid-rows-[1fr,auto] grid-rows-2") == "grid-rows-2"
      assert tw("grid-rows-[repeat(20,minmax(0,1fr))] grid-rows-3") == "grid-rows-3"
    end

    test "handles ambiguous arbitrary values correctly" do
      assert tw("mt-2 mt-[calc(theme(fontSize.4xl)/1.125)]") ==
               "mt-[calc(theme(fontSize.4xl)/1.125)]"

      assert tw("p-2 p-[calc(theme(fontSize.4xl)/1.125)_10px]") ==
               "p-[calc(theme(fontSize.4xl)/1.125)_10px]"

      assert tw("mt-2 mt-[length:theme(someScale.someValue)]") ==
               "mt-[length:theme(someScale.someValue)]"

      assert tw("mt-2 mt-[theme(someScale.someValue)]") == "mt-[theme(someScale.someValue)]"

      assert tw("text-2xl text-[length:theme(someScale.someValue)]") ==
               "text-[length:theme(someScale.someValue)]"

      assert tw("text-2xl text-[calc(theme(fontSize.4xl)/1.125)]") ==
               "text-[calc(theme(fontSize.4xl)/1.125)]"

      # TODO: bg-cover, bg-none, bg-linear-to-r parsers needed
    end

    # TODO: arbitrary custom properties with () syntax not implemented yet
  end

  describe "wonky-inputs.test.ts" do
    test "handles wonky inputs" do
      assert tw(" block") == "block"
      assert tw("block ") == "block"
      assert tw(" block ") == "block"
      assert tw("  block  px-2     py-4  ") == "block px-2 py-4"
      assert tw(["  block  px-2", " ", "     py-4  "]) == "block px-2 py-4"
      assert tw("block\npx-2") == "block px-2"
      assert tw("\nblock\npx-2\n") == "block px-2"
      assert tw("  block\n        \n        px-2   \n          py-4  ") == "block px-2 py-4"

      assert tw("\r  block\n\r        \n        px-2   \n          py-4  ") ==
               "block px-2 py-4"
    end
  end
end
