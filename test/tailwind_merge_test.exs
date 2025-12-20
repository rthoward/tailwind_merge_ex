defmodule TailwindMergeTest do
  use ExUnit.Case

  import TailwindMerge

  doctest TailwindMerge

  test "foo" do
    assert tw("bg-red-500") == "bg-red-500"
  end
end
