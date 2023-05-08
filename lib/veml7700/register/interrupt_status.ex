defmodule VEML7700.Register.InterruptStatus do
  @moduledoc false
  # The interrupt status register (0x06)

  import Bitwise

  # interrupt flags (bits 15:14)
  @interrupt_high 0x4000
  @interrupt_low 0x8000

  @doc """
  Returns true when low threshold exceeded.
  """
  @spec low_threshold?(0..0xFFFF) :: boolean
  def low_threshold?(uint16) do
    (uint16 &&& @interrupt_low) > 0
  end

  @doc """
  Returns true when high threshold exceeded.
  """
  @spec high_threshold?(0..0xFFFF) :: boolean
  def high_threshold?(uint16) do
    (uint16 &&& @interrupt_high) > 0
  end
end
