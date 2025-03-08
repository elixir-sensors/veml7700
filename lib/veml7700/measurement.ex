# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VEML7700.Measurement do
  @moduledoc """
  One sensor measurement report.
  """

  defstruct [:light_lux, :timestamp_ms]

  alias VEML7700.Calc

  @type t :: %__MODULE__{
          light_lux: number,
          timestamp_ms: integer
        }

  @spec new(0..0xFFFF, number) :: VEML7700.Measurement.t()
  def new(raw_light, resolution) when is_number(raw_light) and is_number(resolution) do
    %__MODULE__{
      light_lux: Calc.raw_to_lux(raw_light, resolution),
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end
end
