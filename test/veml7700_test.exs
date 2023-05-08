defmodule VEML7700Test do
  use ExUnit.Case

  alias CircuitsSim.Device.VEML7700, as: VEML7700Sim

  @i2c_address 0x10

  setup context do
    i2c_bus = to_string(context.test)
    veml = context.test

    start_supervised!({VEML7700Sim, bus_name: i2c_bus, address: @i2c_address})
    VEML7700Sim.set_state(i2c_bus, @i2c_address, als_output: 500)

    start_supervised!({VEML7700, bus_name: i2c_bus, address: @i2c_address, name: veml})

    [i2c_bus: i2c_bus, veml: veml]
  end

  test "measure", %{veml: veml} do
    Process.sleep(100)
    {:ok, measurement} = VEML7700.measure(veml)
    assert_in_delta measurement.light_lux, 115.2, 0.1
  end

  test "get and set ALS settings", %{veml: veml} do
    assert {:ok,
            {[
               :als_gain_1_4,
               :als_100ms,
               :als_persistence_1,
               :als_interrupt_disable,
               :als_power_on
             ], 0.2304}} = VEML7700.get_als_config(veml)

    assert {:ok,
            {[
               :als_gain_1,
               :als_200ms,
               :als_persistence_1,
               :als_interrupt_disable,
               :als_power_on
             ], 0.0288}} = VEML7700.set_als_config(veml, [:als_gain_1, :als_200ms])
  end

  test "get and set low threshold", %{veml: veml} do
    assert :ok = VEML7700.set_low_threshold(veml, 123)
    assert {:ok, 123} = VEML7700.get_low_threshold(veml)
  end

  test "get and set high threshold", %{veml: veml} do
    assert :ok = VEML7700.set_high_threshold(veml, 123)
    assert {:ok, 123} = VEML7700.get_high_threshold(veml)
  end

  test "get and set power saving mode", %{veml: veml} do
    assert :ok = VEML7700.set_power_saving(veml, 1, true)
    assert {:ok, {1, true}} = VEML7700.get_power_saving(veml)

    assert :ok = VEML7700.set_power_saving(veml, 2, true)
    assert {:ok, {2, true}} = VEML7700.get_power_saving(veml)

    assert :ok = VEML7700.set_power_saving(veml, 0, false)
    assert {:ok, {0, false}} = VEML7700.get_power_saving(veml)
  end

  test "get interrupt status", %{veml: veml, i2c_bus: i2c_bus} do
    VEML7700Sim.set_state(i2c_bus, @i2c_address, interrupt_status: 0b11000000_00000000)

    assert {:ok, [:high_threshold_crossed, :low_threshold_crossed]} =
             VEML7700.get_interrupt_status(veml)

    VEML7700Sim.set_state(i2c_bus, @i2c_address, interrupt_status: 0b01000000_00000000)
    assert {:ok, [:high_threshold_crossed]} = VEML7700.get_interrupt_status(veml)

    VEML7700Sim.set_state(i2c_bus, @i2c_address, interrupt_status: 0b10000000_00000000)
    assert {:ok, [:low_threshold_crossed]} = VEML7700.get_interrupt_status(veml)

    VEML7700Sim.set_state(i2c_bus, @i2c_address, interrupt_status: 0b00000000_00000000)
    assert {:ok, []} = VEML7700.get_interrupt_status(veml)
  end
end
