defmodule VEML7700.Calc do
  @moduledoc false

  @resolution_max 0.0036
  @gain_max 2
  @integration_time_max 800

  @doc """
  Converts 16-bit value to lux based on the resolution.

  ## Examples

  iex> raw_to_lux(2, 0.2304)
  0.4608

  iex> raw_to_lux(255, 0.2304)
  58.751999999999995
  """
  @spec raw_to_lux(0..0xFFFF, number) :: number
  def raw_to_lux(raw_light, resolution) when is_number(raw_light) and is_number(resolution) do
    raw_light * resolution
  end

  @doc """
  Calculates resolution based on the gain and integration time settings.

  See https://learn.sparkfun.com/tutorials/qwiic-ambient-light-sensor-veml6030-hookup-guide

  ## Examples

    iex> calc_resolution(2, 800)
    0.0036

    iex> calc_resolution(1, 400)
    0.0144

    iex> calc_resolution(1/4, 100)
    0.2304

    iex> calc_resolution(1/8, 25)
    1.8432

    iex> calc_resolution(:als_gain_1_4, :als_100ms)
    0.2304
  """
  @spec calc_resolution(number | atom, number | atom) :: float
  def calc_resolution(gain, integration_time)
      when is_atom(gain) and is_atom(integration_time) do
    calc_resolution(to_number(gain), to_number(integration_time))
  end

  def calc_resolution(gain, integration_time)
      when gain < @gain_max and integration_time < @integration_time_max do
    @resolution_max * (@integration_time_max / integration_time) * (@gain_max / gain)
  end

  def calc_resolution(_, _), do: @resolution_max

  defp to_number(:als_gain_1), do: 1
  defp to_number(:als_gain_2), do: 2
  defp to_number(:als_gain_1_8), do: 1 / 8
  defp to_number(:als_gain_1_4), do: 1 / 4
  defp to_number(:als_25ms), do: 25
  defp to_number(:als_50ms), do: 50
  defp to_number(:als_100ms), do: 100
  defp to_number(:als_200ms), do: 200
  defp to_number(:als_400ms), do: 400
  defp to_number(:als_800ms), do: 800
end
