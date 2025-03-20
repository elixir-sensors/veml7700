# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VEML7700.Register.InterruptStatus do
  @moduledoc false
  # The interrupt status register (0x06)

  import Bitwise

  # interrupt flags (bits 15:14)
  @interrupt_high_crossed 0x4000
  @interrupt_low_crossed 0x8000

  @doc """
  Converts 16-bit integer to list
  """
  @spec from_integer(0..0xFFFF) :: [:low_threshold_crossed | :high_threshold_crossed]
  def from_integer(uint16) do
    result = []
    result = if(low_threshold?(uint16), do: [:low_threshold_crossed | result], else: result)
    result = if(high_threshold?(uint16), do: [:high_threshold_crossed | result], else: result)
    result
  end

  @doc """
  Returns true when low threshold exceeded.
  """
  @spec low_threshold?(0..0xFFFF) :: boolean
  def low_threshold?(uint16) do
    (uint16 &&& @interrupt_low_crossed) > 0
  end

  @doc """
  Returns true when high threshold exceeded.
  """
  @spec high_threshold?(0..0xFFFF) :: boolean
  def high_threshold?(uint16) do
    (uint16 &&& @interrupt_high_crossed) > 0
  end
end
