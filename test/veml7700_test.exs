defmodule VEML7700Test do
  use ExUnit.Case

  alias CircuitsSim.Device.VEML7700, as: VEML7700Sim

  @i2c_address 0x10

  setup context do
    i2c_bus = to_string(context.test)
    start_supervised!({VEML7700Sim, bus_name: i2c_bus, address: @i2c_address})
    VEML7700Sim.set_state(i2c_bus, @i2c_address, als_output: 500)

    start_supervised!({VEML7700, bus_name: i2c_bus, address: @i2c_address, name: context.test})

    :ok
  end

  test "measure", %{test: veml} do
    Process.sleep(100)
    {:ok, measurement} = VEML7700.measure(veml)
    assert_in_delta measurement.light_lux, 115.2, 0.1
  end

  test "set ALS settings", %{test: veml} do
    with {:ok, {settings, resolution}} <- VEML7700.get_als_config(veml) do
      assert settings == [
               :als_gain_1_4,
               :als_100ms,
               :als_persistence_1,
               :als_interrupt_disable,
               :als_power_on
             ]

      assert resolution == 0.2304
    end

    with {:ok, {settings, resolution}} <- VEML7700.set_als_config(veml, [:als_gain_1, :als_200ms]) do
      assert settings == [
               :als_gain_1,
               :als_200ms,
               :als_persistence_1,
               :als_interrupt_disable,
               :als_power_on
             ]

      assert resolution == 0.0288
    end
  end
end
