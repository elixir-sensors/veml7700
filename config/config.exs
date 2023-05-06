import Config

# https://github.com/elixir-circuits/circuits_sim
config :circuits_sim,
  config: [
    {CircuitsSim.Device.VEML7700, bus_name: "i2c-1", address: 0x10},
    {CircuitsSim.Device.VEML7700, bus_name: "i2c-1", address: 0x48}
  ]

config :circuits_i2c, default_backend: CircuitsSim.I2C.Backend
