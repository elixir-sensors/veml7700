# VEML7700

[![Hex version](https://img.shields.io/hexpm/v/veml7700.svg 'Hex version')](https://hex.pm/packages/veml7700)
[![CI](https://github.com/mnishiguchi/veml7700/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mnishiguchi/veml7700/actions/workflows/ci.yml)

<!-- MODULEDOC -->

Use [Vishay ambient light sensor VEML7700](https://www.vishay.com/docs/84286/veml7700.pdf) in Elixir.

<!-- MODULEDOC -->

![](https://www.vishay.com/images/product-images/pt-large/84286-pt-large.jpg)

![](https://cdn.sparkfun.com//assets/parts/1/8/5/5/5/18981-Ambient_Light_Sensor_-_VEML7700__Qwiic_-01.jpg)

## Usage

Here's an example use. VEML7700 sensors are at address `0x10`; VEML6030 typically at `0x48`.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fmnishiguchi%2Fveml7700%2Fblob%2Fmain%2Fnotebooks%2Fbasic_usage.livemd)

```elixir
iex> {:ok, veml} = VEML7700.start_link(bus_name: "i2c-1", bus_address: 0x10)
{:ok, #PID<0.2190.0>}

iex> VEML7700.get_als_config(veml)
{:ok,
 {[:als_gain_1_4,
   :als_100ms,
   :als_persistence_1,
   :als_interrupt_disable,
   :als_shutdown], 0.2304}}

iex> VEML7700.set_als_config(veml, [:als_gain_1, :als_200ms, :als_power_on])
{:ok,
 {[:als_gain_1,
   :als_200ms,
   :als_persistence_1,
   :als_interrupt_disable,
   :als_power_on], 0.0288}}

iex> VEML7700.measure(veml)
{:ok,
  %VEML7700.Measurement{
    light_lux: 9.9072,
    timestamp_ms: 284622415448}}}}
```

For details, see [API reference](https://hexdocs.pm/veml7700/api-reference.html).
