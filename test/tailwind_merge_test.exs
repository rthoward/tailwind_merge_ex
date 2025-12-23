defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

  describe "tw-merge.test.ts" do
    test "twMerge" do
      assert tw("mix-blend-normal mix-blend-multiply") == "mix-blend-multiply"
      assert tw("h-10 h-min") == "h-min"
      assert tw("stroke-black stroke-1") == "stroke-black stroke-1"
      assert tw("stroke-2 stroke-[3]") == "stroke-[3]"
      assert tw("outline-black outline-1") == "outline-black outline-1"
      assert tw("grayscale-0 grayscale-[50%]") == "grayscale-[50%]"
      assert tw("grow grow-[2]") == "grow-[2]"
      assert tw(["grow", [nil, false, [["grow-[2]"]]]]) == "grow-[2]"
    end
  end

  describe "class-group-conflicts.test.ts" do
    test "merges classes from same group correctly" do
      assert tw("overflow-x-auto overflow-x-hidden") == "overflow-x-hidden"
      assert tw("basis-full basis-auto") == "basis-auto"
      assert tw("w-full w-fit") == "w-fit"
      assert tw("overflow-x-auto overflow-x-hidden overflow-x-scroll") == "overflow-x-scroll"

      assert tw("overflow-x-auto hover:overflow-x-hidden overflow-x-scroll") ==
               "hover:overflow-x-hidden overflow-x-scroll"

      assert tw("overflow-x-auto hover:overflow-x-hidden hover:overflow-x-auto overflow-x-scroll") ==
               "hover:overflow-x-auto overflow-x-scroll"

      assert tw("col-span-1 col-span-full") == "col-span-full"
      assert tw("gap-2 gap-px basis-px basis-3") == "gap-px basis-3"
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

      assert tw("line-clamp-1 overflow-auto inline") ==
               "line-clamp-1 overflow-auto inline"
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

    test "conflicts across postfix modifiers" do
      assert tw("text-lg/7 text-lg/8") == "text-lg/8"
      assert tw("text-lg/none leading-9") == "text-lg/none leading-9"
      assert tw("leading-9 text-lg/none") == "text-lg/none"
      assert tw("w-full w-1/2") == "w-1/2"
    end

    test "sorts modifiers correctly" do
      assert tw("c:d:e:block d:c:e:inline") == "d:c:e:inline"
      assert tw("*:before:block *:before:inline") == "*:before:inline"
      assert tw("*:before:block before:*:inline") == "*:before:block before:*:inline"
      assert tw("x:y:*:z:block y:x:*:z:inline") == "y:x:*:z:inline"
    end
  end

  describe "arbitrary-properties.test.ts" do
    test "handles arbitrary property conflicts correctly" do
      assert tw("[paint-order:markers] [paint-order:normal]") == "[paint-order:normal]"

      assert tw("[paint-order:markers] [--my-var:2rem] [paint-order:normal] [--my-var:4px]") ==
               "[paint-order:normal] [--my-var:4px]"
    end

    test "handles arbitrary property conflicts with modifiers correctly" do
      assert tw("[paint-order:markers] hover:[paint-order:normal]") ==
               "[paint-order:markers] hover:[paint-order:normal]"

      assert tw("hover:[paint-order:markers] hover:[paint-order:normal]") ==
               "hover:[paint-order:normal]"

      assert tw("hover:focus:[paint-order:markers] focus:hover:[paint-order:normal]") ==
               "focus:hover:[paint-order:normal]"

      assert tw("[paint-order:markers] [paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]") ==
               "[paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]"

      assert tw("bg-[#B91C1C] bg-radial-[at_50%_75%] bg-radial-[at_25%_25%]") ==
               "bg-[#B91C1C] bg-radial-[at_25%_25%]"
    end

    test "handles complex arbitrary property conflicts correctly" do
      assert tw("[-unknown-prop:::123:::] [-unknown-prop:url(https://hi.com)]") ==
               "[-unknown-prop:url(https://hi.com)]"
    end

    test "handles important modifier correctly" do
      assert tw("![some:prop] [some:other]") == "![some:prop] [some:other]"

      assert tw("![some:prop] [some:other] [some:one] ![some:another]") ==
               "[some:one] ![some:another]"
    end
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
      assert tw("text-[0.5px] text-(--my-0)") == "text-[0.5px] text-(--my-0)"
    end

    test "handles arbitrary length conflicts with labels and modifiers correctly" do
      assert tw("hover:m-[2px] hover:m-[length:var(--c)]") == "hover:m-[length:var(--c)]"

      assert tw("hover:focus:m-[2px] focus:hover:m-[length:var(--c)]") ==
               "focus:hover:m-[length:var(--c)]"

      assert tw("border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]") ==
               "border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]"

      assert tw("border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b") ==
               "border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b"

      assert tw("border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-some-coloooor") ==
               "border-b border-some-coloooor"
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

      assert tw("bg-cover bg-[percentage:30%] bg-[size:200px_100px] bg-[length:200px_100px]") ==
               "bg-[percentage:30%] bg-[length:200px_100px]"

      assert tw("bg-none bg-[url(.)] bg-[image:.] bg-[url:.] bg-[linear-gradient(.)] bg-linear-to-r") ==
               "bg-linear-to-r"

      assert tw("border-[color-mix(in_oklab,var(--background),var(--calendar-color)_30%)] border") ==
               "border-[color-mix(in_oklab,var(--background),var(--calendar-color)_30%)] border"
    end

    test "handles arbitrary custom properties correctly" do
      assert tw("bg-red bg-(--other-red) bg-bottom bg-(position:-my-pos)") ==
               "bg-(--other-red) bg-(position:-my-pos)"

      assert tw(
               "shadow-xs shadow-(shadow:--something) shadow-red shadow-(--some-other-shadow) shadow-(color:--some-color)"
             ) == "shadow-(--some-other-shadow) shadow-(color:--some-color)"
    end
  end

  describe "arbitrary-variants.test.ts" do
    test "basic arbitrary variants" do
      assert tw("[p]:underline [p]:line-through") == "[p]:line-through"
      assert tw("[&>*]:underline [&>*]:line-through") == "[&>*]:line-through"

      assert tw("[&>*]:underline [&>*]:line-through [&_div]:line-through") ==
               "[&>*]:line-through [&_div]:line-through"

      assert tw("supports-[display:grid]:flex supports-[display:grid]:grid") ==
               "supports-[display:grid]:grid"
    end

    test "arbitrary variants with modifiers" do
      assert tw("dark:lg:hover:[&>*]:underline dark:lg:hover:[&>*]:line-through") ==
               "dark:lg:hover:[&>*]:line-through"

      assert tw("dark:lg:hover:[&>*]:underline dark:hover:lg:[&>*]:line-through") ==
               "dark:hover:lg:[&>*]:line-through"

      # Whether a modifier is before or after arbitrary variant matters
      assert tw("hover:[&>*]:underline [&>*]:hover:line-through") ==
               "hover:[&>*]:underline [&>*]:hover:line-through"

      assert tw("hover:dark:[&>*]:underline dark:hover:[&>*]:underline dark:[&>*]:hover:line-through") ==
               "dark:hover:[&>*]:underline dark:[&>*]:hover:line-through"
    end

    test "arbitrary variants with complex syntax in them" do
      assert tw("[@media_screen{@media(hover:hover)}]:underline [@media_screen{@media(hover:hover)}]:line-through") ==
               "[@media_screen{@media(hover:hover)}]:line-through"

      assert tw(
               "hover:[@media_screen{@media(hover:hover)}]:underline hover:[@media_screen{@media(hover:hover)}]:line-through"
             ) == "hover:[@media_screen{@media(hover:hover)}]:line-through"
    end

    test "arbitrary variants with attribute selectors" do
      assert tw("[&[data-open]]:underline [&[data-open]]:line-through") ==
               "[&[data-open]]:line-through"
    end

    test "arbitrary variants with multiple attribute selectors" do
      assert tw(
               "[&[data-foo][data-bar]:not([data-baz])]:underline [&[data-foo][data-bar]:not([data-baz])]:line-through"
             ) == "[&[data-foo][data-bar]:not([data-baz])]:line-through"
    end

    test "multiple arbitrary variants" do
      assert tw("[&>*]:[&_div]:underline [&>*]:[&_div]:line-through") ==
               "[&>*]:[&_div]:line-through"

      assert tw("[&>*]:[&_div]:underline [&_div]:[&>*]:line-through") ==
               "[&>*]:[&_div]:underline [&_div]:[&>*]:line-through"

      assert tw(
               "hover:dark:[&>*]:focus:disabled:[&_div]:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
             ) == "dark:hover:[&>*]:disabled:focus:[&_div]:line-through"

      assert tw(
               "hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
             ) ==
               "hover:dark:[&>*]:focus:[&_div]:disabled:underline dark:hover:[&>*]:disabled:focus:[&_div]:line-through"
    end

    test "arbitrary variants with arbitrary properties" do
      assert tw("[&>*]:[color:red] [&>*]:[color:blue]") == "[&>*]:[color:blue]"

      assert tw(
               "[&[data-foo][data-bar]:not([data-baz])]:nod:noa:[color:red] [&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"
             ) == "[&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"
    end
  end

  describe "non-conflicting-classes.test.ts" do
    test "merges non-conflicting classes correctly" do
      assert tw("border-t border-white/10") == "border-t border-white/10"
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

  describe "important-modifier.test.ts" do
    test "merges tailwind classes with important modifier correctly" do
      assert tw("font-medium! font-bold!") == "font-bold!"
      assert tw("font-medium! font-bold! font-thin") == "font-bold! font-thin"
      assert tw("right-2! -inset-x-px!") == "-inset-x-px!"
      assert tw("focus:inline! focus:block!") == "focus:block!"
      assert tw("[--my-var:20px]! [--my-var:30px]!") == "[--my-var:30px]!"

      # Tailwind CSS v3 legacy syntax
      assert tw("font-medium! !font-bold") == "!font-bold"
      assert tw("!font-medium !font-bold") == "!font-bold"
      assert tw("!font-medium !font-bold font-thin") == "!font-bold font-thin"
      assert tw("!right-2 !-inset-x-px") == "!-inset-x-px"
      assert tw("focus:!inline focus:!block") == "focus:!block"
      assert tw("![--my-var:20px] ![--my-var:30px]") == "![--my-var:30px]"
    end
  end

  describe "pseudo-variants.test.ts" do
    test "handles pseudo variants conflicts properly" do
      assert tw("empty:p-2 empty:p-3") == "empty:p-3"
      assert tw("hover:empty:p-2 hover:empty:p-3") == "hover:empty:p-3"
      assert tw("read-only:p-2 read-only:p-3") == "read-only:p-3"
    end

    test "handles pseudo variant group conflicts properly" do
      assert tw("group-empty:p-2 group-empty:p-3") == "group-empty:p-3"
      assert tw("peer-empty:p-2 peer-empty:p-3") == "peer-empty:p-3"
      assert tw("group-empty:p-2 peer-empty:p-3") == "group-empty:p-2 peer-empty:p-3"
      assert tw("hover:group-empty:p-2 hover:group-empty:p-3") == "hover:group-empty:p-3"
      assert tw("group-read-only:p-2 group-read-only:p-3") == "group-read-only:p-3"
    end
  end

  describe "negative-values.test.ts" do
    test "handles negative value conflicts correctly" do
      assert tw("-m-2 -m-5") == "-m-5"
      assert tw("-top-12 -top-2000") == "-top-2000"
    end

    test "handles conflicts between positive and negative values correctly" do
      assert tw("-m-2 m-auto") == "m-auto"
      assert tw("top-12 -top-69") == "-top-69"
    end

    test "handles conflicts across groups with negative values correctly" do
      assert tw("-right-1 inset-x-1") == "inset-x-1"
      assert tw("hover:focus:-right-1 focus:hover:inset-x-1") == "focus:hover:inset-x-1"
    end
  end

  describe "per-side-border-colors.test.ts" do
    test "merges classes with per-side border colors correctly" do
      assert tw("border-t-some-blue border-t-other-blue") == "border-t-other-blue"
      assert tw("border-t-some-blue border-some-blue") == "border-some-blue"

      assert tw("border-some-blue border-s-some-blue") ==
               "border-some-blue border-s-some-blue"

      assert tw("border-e-some-blue border-some-blue") == "border-some-blue"
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

  describe "content-utilities.test.ts" do
    test "merges content utilities correctly" do
      assert tw("content-['hello'] content-[attr(data-content)]") ==
               "content-[attr(data-content)]"
    end
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

  describe "tailwind-css-versions.test.ts" do
    test "supports Tailwind CSS v3.3 features" do
      assert tw("text-red text-lg/7 text-lg/8") == "text-red text-lg/8"

      assert tw([
               "start-0 start-1",
               "end-0 end-1",
               "ps-0 ps-1 pe-0 pe-1",
               "ms-0 ms-1 me-0 me-1",
               "rounded-s-sm rounded-s-md rounded-e-sm rounded-e-md",
               "rounded-ss-sm rounded-ss-md rounded-ee-sm rounded-ee-md"
             ]) ==
               "start-1 end-1 ps-1 pe-1 ms-1 me-1 rounded-s-md rounded-e-md rounded-ss-md rounded-ee-md"

      assert tw("start-0 end-0 inset-0 ps-0 pe-0 p-0 ms-0 me-0 m-0 rounded-ss rounded-es rounded-s") ==
               "inset-0 p-0 m-0 rounded-s"

      assert tw("hyphens-auto hyphens-manual") == "hyphens-manual"

      assert tw("from-0% from-10% from-[12.5%] via-0% via-10% via-[12.5%] to-0% to-10% to-[12.5%]") ==
               "from-[12.5%] via-[12.5%] to-[12.5%]"

      assert tw("from-0% from-red") == "from-0% from-red"

      assert tw("list-image-none list-image-[url(./my-image.png)] list-image-[var(--value)]") ==
               "list-image-[var(--value)]"

      assert tw("caption-top caption-bottom") == "caption-bottom"
      assert tw("line-clamp-2 line-clamp-none line-clamp-[10]") == "line-clamp-[10]"
      assert tw("delay-150 delay-0 duration-150 duration-0") == "delay-0 duration-0"
      assert tw("justify-normal justify-center justify-stretch") == "justify-stretch"
      assert tw("content-normal content-center content-stretch") == "content-stretch"
      assert tw("whitespace-nowrap whitespace-break-spaces") == "whitespace-break-spaces"
    end

    test "supports Tailwind CSS v3.4 features" do
      assert tw("h-svh h-dvh w-svw w-dvw") == "h-dvh w-dvw"

      assert tw(
               "has-[[data-potato]]:p-1 has-[[data-potato]]:p-2 group-has-[:checked]:grid group-has-[:checked]:flex"
             ) == "has-[[data-potato]]:p-2 group-has-[:checked]:flex"

      assert tw("text-wrap text-pretty") == "text-pretty"
      assert tw("w-5 h-3 size-10 w-12") == "size-10 w-12"

      assert tw("grid-cols-2 grid-cols-subgrid grid-rows-5 grid-rows-subgrid") ==
               "grid-cols-subgrid grid-rows-subgrid"

      assert tw("min-w-0 min-w-50 min-w-px max-w-0 max-w-50 max-w-px") == "min-w-px max-w-px"

      assert tw("forced-color-adjust-none forced-color-adjust-auto") ==
               "forced-color-adjust-auto"

      assert tw("appearance-none appearance-auto") == "appearance-auto"
      assert tw("float-start float-end clear-start clear-end") == "float-end clear-end"
      assert tw("*:p-10 *:p-20 hover:*:p-10 hover:*:p-20") == "*:p-20 hover:*:p-20"
    end

    test "supports Tailwind CSS v4.0 features" do
      assert tw("transform-3d transform-flat") == "transform-flat"

      assert tw("rotate-12 rotate-x-2 rotate-none rotate-y-3") ==
               "rotate-x-2 rotate-none rotate-y-3"

      assert tw("perspective-dramatic perspective-none perspective-midrange") ==
               "perspective-midrange"

      assert tw("perspective-origin-center perspective-origin-top-left") ==
               "perspective-origin-top-left"

      assert tw("bg-linear-to-r bg-linear-45") == "bg-linear-45"

      assert tw("bg-linear-to-r bg-radial-[something] bg-conic-10") == "bg-conic-10"

      assert tw("ring-4 ring-orange inset-ring inset-ring-3 inset-ring-blue") ==
               "ring-4 ring-orange inset-ring-3 inset-ring-blue"

      assert tw("field-sizing-content field-sizing-fixed") == "field-sizing-fixed"
      assert tw("scheme-normal scheme-dark") == "scheme-dark"

      assert tw("font-stretch-expanded font-stretch-[66.66%] font-stretch-50%") ==
               "font-stretch-50%"

      assert tw("col-span-full col-2 row-span-3 row-4") == "col-2 row-4"
      assert tw("via-red-500 via-(--mobile-header-gradient)") == "via-(--mobile-header-gradient)"

      assert tw("via-red-500 via-(length:--mobile-header-gradient)") ==
               "via-red-500 via-(length:--mobile-header-gradient)"
    end

    test "supports Tailwind CSS v4.1 features" do
      assert tw("items-baseline items-baseline-last") == "items-baseline-last"
      assert tw("self-baseline self-baseline-last") == "self-baseline-last"

      assert tw("place-content-center place-content-end-safe place-content-center-safe") ==
               "place-content-center-safe"

      assert tw("items-center-safe items-baseline items-end-safe") == "items-end-safe"
      assert tw("wrap-break-word wrap-normal wrap-anywhere") == "wrap-anywhere"
      assert tw("text-shadow-none text-shadow-2xl") == "text-shadow-2xl"

      assert tw("text-shadow-none text-shadow-md text-shadow-red text-shadow-red-500 shadow-red shadow-3xs") ==
               "text-shadow-md text-shadow-red-500 shadow-red shadow-3xs"

      assert tw("mask-add mask-subtract") == "mask-subtract"

      assert tw([
               # mask-image
               "mask-(--foo) mask-[foo] mask-none",
               # mask-image-linear-pos
               "mask-linear-1 mask-linear-2",
               # mask-image-linear-from-pos
               "mask-linear-from-[position:test] mask-linear-from-3",
               # mask-image-linear-to-pos
               "mask-linear-to-[position:test] mask-linear-to-3",
               # mask-image-linear-from-color
               "mask-linear-from-color-red mask-linear-from-color-3",
               # mask-image-linear-to-color
               "mask-linear-to-color-red mask-linear-to-color-3",
               # mask-image-t-from-pos
               "mask-t-from-[position:test] mask-t-from-3",
               # mask-image-t-to-pos
               "mask-t-to-[position:test] mask-t-to-3",
               # mask-image-t-from-color
               "mask-t-from-color-red mask-t-from-color-3",
               # mask-image-radial
               "mask-radial-(--test) mask-radial-[test]",
               # mask-image-radial-from-pos
               "mask-radial-from-[position:test] mask-radial-from-3",
               # mask-image-radial-to-pos
               "mask-radial-to-[position:test] mask-radial-to-3",
               # mask-image-radial-from-color
               "mask-radial-from-color-red mask-radial-from-color-3"
             ]) ==
               "mask-none mask-linear-2 mask-linear-from-3 mask-linear-to-3 mask-linear-from-color-3 mask-linear-to-color-3 mask-t-from-3 mask-t-to-3 mask-t-from-color-3 mask-radial-[test] mask-radial-from-3 mask-radial-to-3 mask-radial-from-color-3"

      assert tw([
               # mask-image
               "mask-(--something) mask-[something]",
               # mask-position
               "mask-top-left mask-center mask-(position:--var) mask-[position:1px_1px] mask-position-(--var) mask-position-[1px_1px]"
             ]) == "mask-[something] mask-position-[1px_1px]"

      assert tw([
               # mask-image
               "mask-(--something) mask-[something]",
               # mask-size
               "mask-auto mask-[size:foo] mask-(size:--foo) mask-size-[foo] mask-size-(--foo) mask-cover mask-contain"
             ]) == "mask-[something] mask-contain"

      assert tw("mask-type-luminance mask-type-alpha") == "mask-type-alpha"

      assert tw("shadow-md shadow-lg/25 text-shadow-md text-shadow-lg/25") ==
               "shadow-lg/25 text-shadow-lg/25"

      assert tw("drop-shadow-some-color drop-shadow-[#123456] drop-shadow-lg drop-shadow-[10px_0]") ==
               "drop-shadow-[#123456] drop-shadow-[10px_0]"

      assert tw("drop-shadow-[#123456] drop-shadow-some-color") == "drop-shadow-some-color"
      assert tw("drop-shadow-2xl drop-shadow-[shadow:foo]") == "drop-shadow-[shadow:foo]"
    end

    test "supports Tailwind CSS v4.1.5 features" do
      assert tw("h-12 h-lh") == "h-lh"
      assert tw("min-h-12 min-h-lh") == "min-h-lh"
      assert tw("max-h-12 max-h-lh") == "max-h-lh"
    end
  end
end
