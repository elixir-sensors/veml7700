defmodule VEML7700.Register.InterruptStatusTest do
  use ExUnit.Case
  alias VEML7700.Register.InterruptStatus
  doctest VEML7700.Register.InterruptStatus

  test "read high threshold status flag and return boolean" do
    assert(InterruptStatus.high_threshold?(0b01000000_00000000))
    assert(InterruptStatus.high_threshold?(0b11000000_00000000))
    refute(InterruptStatus.high_threshold?(0))
  end

  test "read low threshold status flag and return boolean" do
    assert(InterruptStatus.low_threshold?(0b10000000_00000000))
    assert(InterruptStatus.low_threshold?(0b11000000_00000000))
    refute(InterruptStatus.low_threshold?(0))
  end
end
