defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

  test "foo" do
    assert tw("bg-red-500") == "bg-red-500"
    assert tw(["bg-red-500"]) == "bg-red-500"
    assert tw([nil, "bg-red-500", [false]]) == "bg-red-500"
    assert tw(["", [block: false]]) == ""
    assert tw(["", [block: true]]) == "block"
  end
end
