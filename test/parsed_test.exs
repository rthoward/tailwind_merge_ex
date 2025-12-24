defmodule TailwindMerge.ParsedTest do
  use ExUnit.Case

  alias TailwindMerge.Parsed

  test "foo" do
    assert %Parsed{group: :bg, important?: false, modifiers: []} = Parsed.new("bg-red")

    assert %Parsed{group: :m} = Parsed.new("m-2")
    assert %Parsed{group: :m} = Parsed.new("-m-2")
  end
end
