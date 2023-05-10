defmodule VEML7700.CommTest do
  use ExUnit.Case
  alias VEML7700.Comm
  doctest VEML7700.Comm

  setup %{} do
    {:ok, transport} = Comm.init_transport("i2c-1", 0x10, [])
    {:ok, transport: transport}
  end

  test "read and write als_config", %{transport: transport} do
    {:ok, result1} = Comm.read_als_config(transport)

    assert result1 ==
             {[
                :als_gain_1,
                :als_100ms,
                :als_persistence_1,
                :als_interrupt_disable,
                :als_power_on
              ], 0.0576}

    {:ok, result2} = Comm.write_als_config(transport, [:als_gain_1_4, :als_200ms])

    assert result2 ==
             {[
                :als_gain_1_4,
                :als_200ms,
                :als_persistence_1,
                :als_interrupt_disable,
                :als_power_on
              ], 0.1152}
  end

  test "read and write low threshold", %{transport: transport} do
    :ok = Comm.write_low_threshold(transport, 123)
    assert {:ok, 123} = Comm.read_low_threshold(transport)

    :ok = Comm.write_low_threshold(transport, 234)
    assert {:ok, 234} = Comm.read_low_threshold(transport)
  end

  test "read and write power saving mode", %{transport: transport} do
    :ok = Comm.write_power_saving(transport, 1, true)
    assert {:ok, {1, true}} = Comm.read_power_saving(transport)

    :ok = Comm.write_power_saving(transport, 1, false)
    assert {:ok, {1, false}} = Comm.read_power_saving(transport)
  end

  test "read als output data", %{transport: transport} do
    resolution = 0.0576
    {:ok, result} = Comm.read_als_output(transport, resolution)

    assert %{light_lux: _, timestamp_ms: _} = result
  end

  test "read interrupt status", %{transport: transport} do
    {:ok, result} = Comm.read_interrupt_status(transport)

    assert result == []
  end
end
