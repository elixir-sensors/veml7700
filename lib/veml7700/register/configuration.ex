defmodule VEML7700.Register.Configuration do
  @moduledoc """
  The configuration register (0x00).
  """

  alias VEML7700.Calc

  import Bitwise

  defstruct als_gain: 0,
            als_integration_time: 0,
            als_persistence: 0,
            als_interrupt_enable: 0,
            als_shutdown: 0

  # bitmask and position
  @register_bits %{
    # ALS gain setting (bits 12:11)
    als_gain: {0b11, 11},
    # ALS integration time setting (bits 9:6)
    als_integration_time: {0b1111, 6},
    # ALS persistence protect number setting (bits 5:4)
    als_persistence: {0b11, 4},
    # ALS interrupt enable setting (bit 1)
    als_interrupt_enable: {0b1, 1},
    # ALS shutdown setting (bit 0)
    als_shutdown: {0b1, 0}
  }

  @register_names Map.keys(@register_bits)

  # unique setting name, register name, and setting value
  @possible_settings [
    {:als_gain_1, :als_gain, 0b00},
    {:als_gain_2, :als_gain, 0b01},
    {:als_gain_1_8, :als_gain, 0b10},
    {:als_gain_1_4, :als_gain, 0b11},
    {:als_25ms, :als_integration_time, 0b1100},
    {:als_50ms, :als_integration_time, 0b1000},
    {:als_100ms, :als_integration_time, 0b0000},
    {:als_200ms, :als_integration_time, 0b0001},
    {:als_400ms, :als_integration_time, 0b0010},
    {:als_800ms, :als_integration_time, 0b0011},
    {:als_persistence_1, :als_persistence, 0b00},
    {:als_persistence_2, :als_persistence, 0b01},
    {:als_persistence_4, :als_persistence, 0b10},
    {:als_persistence_8, :als_persistence, 0b11},
    {:als_interrupt_enable, :als_interrupt_enable, 1},
    {:als_interrupt_disable, :als_interrupt_enable, 0},
    {:als_shutdown, :als_shutdown, 1},
    {:als_power_on, :als_shutdown, 0}
  ]

  @spec new(keyword) :: struct
  def new(kv \\ []), do: struct!(__MODULE__, kv)

  @doc """
  Sets configuration values with one or more setting name atoms
  """
  @spec set(map, atom | [atom]) :: map
  def set(t, setting_name) when is_atom(setting_name) do
    set(t, [setting_name])
  end

  def set(t, setting_names) when is_list(setting_names) do
    Enum.reduce(@possible_settings, t, fn {setting_name, register, value}, acc ->
      if setting_name in setting_names do
        struct!(acc, [{register, value}])
      else
        acc
      end
    end)
  end

  @doc """
  Gets configuration values with one or more setting name atoms
  """
  @spec to_list(map) :: [atom]
  def to_list(t), do: get(t, @register_names)

  @spec get(map, atom) :: atom
  def get(t, register_name) when is_atom(register_name) do
    get(t, [register_name]) |> List.first()
  end

  @spec get(map, [atom]) :: [atom]
  def get(t, register_names) when is_list(register_names) do
    Enum.reduce(@possible_settings, [], fn {setting_name, register_name, value}, acc ->
      if register_name in register_names and value == Map.fetch!(t, register_name) do
        [setting_name | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Converts struct to 16-bit integer
  """
  @spec to_integer(map) :: 0..0xFFFF
  def to_integer(t) do
    Enum.reduce(@register_names, 0, &(&2 ||| to_integer(t, &1)))
  end

  defp to_integer(t, key) do
    {_mask, position} = Map.fetch!(@register_bits, key)
    Map.fetch!(t, key) <<< position
  end

  @doc """
  Converts 16-bit integer to struct
  """
  @spec from_integer(0..0xFFFF) :: struct
  def from_integer(uint16) do
    @register_names |> Enum.map(&{&1, from_integer(uint16, &1)}) |> new()
  end

  defp from_integer(uint16, key) do
    {mask, position} = Map.fetch!(@register_bits, key)
    uint16 >>> position &&& mask
  end

  @spec resolution(map) :: float
  def resolution(t) do
    als_gain = get(t, :als_gain)
    als_integration_time = get(t, :als_integration_time)

    Calc.calc_resolution(als_gain, als_integration_time)
  end
end
