defmodule BlendendPlaygroundPhx.CalculationTest do
  use ExUnit.Case, async: true

  alias BlendendPlaygroundPhx.Calculation

  describe "rand_between_int/2" do
    test "returns an integer in the inclusive range" do
      Enum.each(1..250, fn _ ->
        v = Calculation.rand_between_int(3, 5)
        assert is_integer(v)
        assert v in 3..5
      end)
    end

    test "works when min > max" do
      Enum.each(1..250, fn _ ->
        v = Calculation.rand_between_int(5, 3)
        assert v in 3..5
      end)
    end

    test "returns the same value when min == max" do
      assert Calculation.rand_between_int(7, 7) == 7
    end
  end
end
