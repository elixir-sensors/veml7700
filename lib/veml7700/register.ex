defmodule VEML7700.Register do
  @moduledoc false

  @doc """
  Returns a register address for a command.
  """
  def command_register(:als_config), do: 0
  def command_register(:als_threshold_high), do: 1
  def command_register(:als_threshold_low), do: 2
  def command_register(:als_power_saving), do: 3
  def command_register(:als_output), do: 4
  def command_register(:white_output), do: 5
  def command_register(:interrupt_status), do: 6
end
