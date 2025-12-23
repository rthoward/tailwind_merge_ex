defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

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
      # # assert tw("basis-full basis-auto") == "basis-auto"  # TODO: basis not implemented
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
      assert tw("text-3.5xl text-black") == "text-3.5xl text-black"
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
