defmodule VEML7700.Register.PowerSavingMode do
  @moduledoc """
  The power saving mode register (0x03).
  """

  import Bitwise

  defstruct mode: 0, enabled: 0

  # bitmask and position
  @bits %{
    # bits 2:1
    mode: {0b11, 1},
    # bit 0
    enabled: {0b1, 0}
  }

  @spec new(keyword) :: struct
  def new(kv \\ []), do: struct!(__MODULE__, kv)

  @spec set(struct, atom) :: struct
  def set(t, :mode_1), do: %{t | mode: 0b00}
  def set(t, :mode_2), do: %{t | mode: 0b01}
  def set(t, :mode_3), do: %{t | mode: 0b10}
  def set(t, :mode_4), do: %{t | mode: 0b11}
  def set(t, :enable), do: %{t | enabled: 1}
  def set(t, :disable), do: %{t | enabled: 0}

  @doc """
  Converts struct to 16-bit integer
  """
  @spec to_integer(map) :: 0..0xFFFF
  def to_integer(t) do
    Enum.reduce(Map.keys(@bits), 0, &(&2 ||| to_integer(t, &1)))
  end

  defp to_integer(t, key) do
    {_mask, position} = Map.fetch!(@bits, key)
    Map.fetch!(t, key) <<< position
  end

  @doc """
  Converts 16-bit integer to struct
  """
  @spec from_integer(0..0xFFFF) :: struct
  def from_integer(uint16) do
    Map.keys(@bits) |> Enum.map(&{&1, from_integer(uint16, &1)}) |> new()
  end

  defp from_integer(uint16, key) do
    {mask, position} = Map.fetch!(@bits, key)
    uint16 >>> position &&& mask
  end
end
