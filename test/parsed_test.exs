defmodule TailwindMerge.ParsedTest do
  use ExUnit.Case

  alias TailwindMerge.Parsed

  test "foo" do
    assert %Parsed{group: :bg, important?: false, modifiers: []} = Parsed.new("bg-red")

    assert %Parsed{group: :m} = Parsed.new("m-2")
    assert %Parsed{group: :m} = Parsed.new("-m-2")

    assert %Parsed{group: :font_size} = Parsed.new("text-[0.5px]")
    assert %Parsed{group: :text_color} = Parsed.new("text-(--my-0)")
  end
end
