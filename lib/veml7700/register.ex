defmodule VEML7700.Register do
  @moduledoc false

  # command registers
  @cmd_register %{
    als_config: 0,
    als_threshold_high: 1,
    als_threshold_low: 2,
    als_power_saving: 3,
    als_output: 4,
    white_output: 5,
    interrupt_status: 6
  }

  @spec command_register(atom) :: 0..6
  def command_register(name), do: Map.fetch!(@cmd_register, name)
end
