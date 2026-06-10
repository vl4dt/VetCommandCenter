defmodule VetCommandCenter.UlidTest do
  use ExUnit.Case, async: true
  alias VetCommandCenter.Ulid

  describe "generate/0" do
    test "returns a 26-character string" do
      ulid = Ulid.generate()
      assert is_binary(ulid)
      assert byte_size(ulid) == 26
    end

    test "generates unique values" do
      ids = for _ <- 1..10, do: Ulid.generate()
      assert length(ids) == length(Enum.uniq(ids))
    end

    test "generated ULIDs are valid" do
      ulid = Ulid.generate()
      assert Ulid.valid?(ulid)
    end
  end

  describe "valid?/1" do
    test "accepts valid 26-char ULID strings" do
      assert Ulid.valid?(Ulid.generate())
    end

    test "rejects strings that are too short" do
      refute Ulid.valid?("01HK6HBW2X7A9BQ5J3F8M0N")
    end

    test "rejects strings that are too long" do
      refute Ulid.valid?("01HK6HBW2X7A9BQ5J3F8M0N1P2X")
    end

    test "rejects non-string input" do
      refute Ulid.valid?(123)
      refute Ulid.valid?(nil)
    end
  end
end
