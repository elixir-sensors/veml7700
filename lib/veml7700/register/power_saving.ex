# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VEML7700.Register.PowerSaving do
  @moduledoc false
  # The configuration register (0x03)

  defstruct mode: 0, enabled: 0, reserved1: 0, reserved2: 0

  @spec new(keyword) :: struct
  def new(kv \\ []), do: struct!(__MODULE__, kv)

  @spec set_enabled(struct, boolean) :: struct
  def set_enabled(t, true), do: struct!(t, enabled: 1)
  def set_enabled(t, false), do: struct!(t, enabled: 0)

  @spec set_mode(struct, 0..3) :: struct
  def set_mode(t, mode) when is_integer(mode) and mode in 0..3 do
    struct!(t, mode: mode)
  end

  @doc """
  Converts struct to 16-bit integer
  """
  @spec to_integer(struct) :: 0..0xFFFF
  def to_integer(t) do
    <<value::little-16>> = <<t.reserved1::5, t.mode::2, t.enabled::1, t.reserved2::8>>
    value
  end

  @doc """
  Converts 16-bit integer to struct
  """
  @spec from_integer(0..0xFFFF) :: struct
  def from_integer(value) do
    <<reserved1::5, mode::2, enabled::1, reserved2::8>> = <<value::little-16>>
    new(reserved1: reserved1, mode: mode, enabled: enabled, reserved2: reserved2)
  end

  @spec to_tuple(struct) :: {0..3, boolean}
  def to_tuple(t), do: {t.mode, enabled?(t)}

  @spec enabled?(struct) :: boolean
  def enabled?(%{enabled: 1}), do: true
  def enabled?(%{enabled: 0}), do: false
end
