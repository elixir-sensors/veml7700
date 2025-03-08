# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VEML7700.Register.ConfigurationTest do
  use ExUnit.Case
  alias VEML7700.Register.Configuration
  doctest VEML7700.Register.Configuration

  test "init with default arguments" do
    assert Configuration.new() == %Configuration{
             als_gain: 0,
             als_integration_time: 0,
             als_persistence: 0,
             als_interrupt_enable: 0,
             als_shutdown: 0
           }
  end

  test "init with initial values" do
    assert Configuration.new(als_gain: 0b11, als_shutdown: 1) == %Configuration{
             als_gain: 3,
             als_integration_time: 0,
             als_persistence: 0,
             als_interrupt_enable: 0,
             als_shutdown: 1
           }
  end

  test "set with atom" do
    config =
      Configuration.new()
      |> Configuration.set(:als_gain_1_4)
      |> Configuration.set(:als_200ms)

    assert config == %Configuration{
             als_gain: 3,
             als_integration_time: 1,
             als_persistence: 0,
             als_interrupt_enable: 0,
             als_shutdown: 0
           }
  end

  test "set with atom list" do
    config =
      Configuration.new()
      |> Configuration.set([:als_gain_1_4, :als_200ms])

    assert config == %Configuration{
             als_gain: 3,
             als_integration_time: 1,
             als_persistence: 0,
             als_interrupt_enable: 0,
             als_shutdown: 0
           }
  end

  test "get all current setting names" do
    setting_name =
      %Configuration{
        als_gain: 3,
        als_integration_time: 1,
        als_persistence: 0,
        als_interrupt_enable: 0,
        als_shutdown: 0
      }
      |> Configuration.to_list()

    assert setting_name == [
             :als_gain_1_4,
             :als_200ms,
             :als_persistence_1,
             :als_interrupt_disable,
             :als_power_on
           ]
  end

  test "get with register name" do
    setting_name =
      %Configuration{
        als_gain: 3,
        als_integration_time: 1,
        als_persistence: 0,
        als_interrupt_enable: 0,
        als_shutdown: 0
      }
      |> Configuration.get(:als_integration_time)

    assert setting_name == :als_200ms
  end

  test "get with register name list" do
    setting_names =
      %Configuration{
        als_gain: 3,
        als_integration_time: 1,
        als_persistence: 0,
        als_interrupt_enable: 0,
        als_shutdown: 0
      }
      |> Configuration.get([:als_gain, :als_integration_time])

    assert setting_names == [:als_gain_1_4, :als_200ms]
  end

  test "convert struct to integer" do
    config = Configuration.new(als_gain: 0b11, als_shutdown: 1)
    assert Configuration.to_integer(config) == 0b00011000_00000001
  end

  test "convert integer to struct" do
    assert Configuration.from_integer(0b00011000_00000001) == %Configuration{
             als_gain: 3,
             als_integration_time: 0,
             als_persistence: 0,
             als_interrupt_enable: 0,
             als_shutdown: 1
           }
  end
end
