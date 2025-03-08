# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VEML7700 do
  @moduledoc File.read!("README.md")
             |> String.split("<!-- MODULEDOC -->")
             |> Enum.fetch!(1)

  use GenServer
  alias VEML7700.Comm
  alias VEML7700.Measurement
  require Logger

  @typedoc """
  VEML7700 GenServer start_link options
  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:bus_address` - the address of the VEML7700 (defaults to `0x10`)
  * `:retries` - the number of retries before failing (defaults to no retries)
  * `:als_gain` - ambient light gain setting (defaults to `:als_gain_1_4`)
  * `:als_integration_time` - ambient light integration time setting (defaults to `:als_100ms`)
  """
  @type option() ::
          {:name, atom}
          | {:bus_name, String.t()}
          | {:bus_address, 0x10 | 0x48}
          | {:retries, pos_integer}
          | {:als_gain, als_gain}
          | {:als_integration_time, als_integration_time}

  @typedoc """
  Ambient light gain setting.
  See https://learn.sparkfun.com/tutorials/qwiic-ambient-light-sensor-veml6030-hookup-guide
  """
  @type als_gain() ::
          :als_gain_1 | :als_gain_2 | :als_gain_1_4 | :als_gain_1_8

  @typedoc """
  Ambient light integration time setting. Longer time has higher sensitivity.
  See https://learn.sparkfun.com/tutorials/qwiic-ambient-light-sensor-veml6030-hookup-guide
  """
  @type als_integration_time() ::
          :als_25ms | :als_50ms | :als_100ms | :als_200ms | :als_400ms | :als_800ms

  @default_bus_name "i2c-1"
  @default_bus_address 0x10
  @default_run_interval_ms 1000
  @default_als_gain :als_gain_1_4
  @default_als_integration_time :als_100ms

  ## Public API

  @doc """
  Start a new GenServer for interacting with a VEML7700.
  """
  @spec start_link([option]) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: options[:name])
  end

  @doc """
  Measure the current light.
  An error is returned if the I2C transactions fail.
  """
  @spec measure(GenServer.server()) :: {:error, any} | {:ok, Measurement.t()}
  def measure(server \\ __MODULE__) do
    GenServer.call(server, :measure)
  end

  @doc """
  Get the ambient light sensor settings.
  """
  @spec get_als_config(GenServer.server()) ::
          {:error, any} | {:ok, {setting_names :: [atom], resolution :: float}}
  def get_als_config(server \\ __MODULE__) do
    GenServer.call(server, :get_als_config)
  end

  @doc """
  Set the ambient light sensor settings.
  """
  @spec set_als_config(GenServer.server(), als_gain | als_integration_time) ::
          {:error, any} | {:ok, {setting_names :: [atom], resolution :: float}}
  def set_als_config(server \\ __MODULE__, als_setting_names) do
    GenServer.call(server, {:set_als_config, als_setting_names})
  end

  @doc """
  Get the low threshold.
  """
  @spec get_low_threshold(GenServer.server()) :: {:error, any} | {:ok, 0..0xFFFF}
  def get_low_threshold(server \\ __MODULE__) do
    GenServer.call(server, :get_low_threshold)
  end

  @doc """
  Set the low threshold.
  """
  @spec set_low_threshold(GenServer.server(), 0..0xFFFF) :: {:error, any} | :ok
  def set_low_threshold(server \\ __MODULE__, value) do
    GenServer.call(server, {:set_low_threshold, value})
  end

  @doc """
  Get the high threshold.
  """
  @spec get_high_threshold(GenServer.server()) :: {:error, any} | {:ok, 0..0xFFFF}
  def get_high_threshold(server \\ __MODULE__) do
    GenServer.call(server, :get_high_threshold)
  end

  @doc """
  Set the high threshold.
  """
  @spec set_high_threshold(GenServer.server(), 0..0xFFFF) :: {:error, any} | :ok
  def set_high_threshold(server \\ __MODULE__, value) do
    GenServer.call(server, {:set_high_threshold, value})
  end

  @doc """
  Get the power saving mode.
  """
  @spec get_power_saving(GenServer.server()) ::
          {:error, any} | {:ok, {mode :: 0..3, enabled :: boolean}}
  def get_power_saving(server \\ __MODULE__) do
    GenServer.call(server, :get_power_saving)
  end

  @doc """
  Set the power saving mode.
  """
  @spec set_power_saving(GenServer.server(), mode :: 0..3, enabled :: boolean) ::
          {:error, any} | :ok
  def set_power_saving(server \\ __MODULE__, mode, enabled) do
    GenServer.call(server, {:set_power_saving, mode, enabled})
  end

  @doc """
  Get the interrupt status.
  """
  @spec get_interrupt_status(GenServer.server()) :: {:error, any} | {:ok, 0..0xFFFF}
  def get_interrupt_status(server \\ __MODULE__) do
    GenServer.call(server, :get_interrupt_status)
  end

  ## GenServer callbacks

  @impl GenServer
  def init(init_args) do
    bus_name = init_args[:bus_name] || @default_bus_name
    bus_address = init_args[:bus_address] || @default_bus_address
    run_interval_ms = init_args[:run_interval_ms] || @default_run_interval_ms
    i2c_options = Keyword.take(init_args, [:retries])
    als_options = Keyword.take(init_args, [:als_gain, :als_integration_time])

    Logger.info(
      "VEML7700: starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    case Comm.init_transport(bus_name, bus_address, i2c_options) do
      {:ok, transport} ->
        state = %{
          transport: transport,
          last_measurement: nil,
          run_interval_ms: run_interval_ms,
          resolution: nil
        }

        {:ok, state, {:continue, {:initialize_device, als_options}}}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_continue({:initialize_device, options}, state) do
    als_gain = options[:als_gain] || @default_als_gain
    als_integration_time = options[:als_integration_time] || @default_als_integration_time
    als_config = [als_gain, als_integration_time, :als_power_on]

    case Comm.write_als_config(state.transport, als_config) do
      {:ok, {setting_names, resolution}} ->
        new_state = update_state_after_config_change(state, {setting_names, resolution})

        # initial run
        send(self(), :perform_measurement)

        {:noreply, new_state}

      {:error, error} ->
        {:stop, error}
    end
  end

  def handle_continue(:schedule_next_run, state) do
    Process.send_after(self(), :perform_measurement, state.run_interval_ms)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) when is_nil(state.last_measurement) do
    {:reply, {:error, :no_measurement}, state}
  end

  def handle_call(:measure, _from, state) do
    {:reply, {:ok, state.last_measurement}, state}
  end

  def handle_call(:get_als_config, _from, state) do
    result = Comm.read_als_config(state.transport)

    {:reply, result, state}
  end

  def handle_call({:set_als_config, als_setting_names}, _from, state) do
    case result = Comm.write_als_config(state.transport, als_setting_names) do
      {:ok, {setting_names, resolution}} ->
        new_state = update_state_after_config_change(state, {setting_names, resolution})

        {:reply, result, new_state}

      {:error, error} ->
        {:stop, error}
    end
  end

  def handle_call(:get_low_threshold, _from, state) do
    result = Comm.read_low_threshold(state.transport)

    {:reply, result, state}
  end

  def handle_call({:set_low_threshold, value}, _from, state) do
    result = Comm.write_low_threshold(state.transport, value)

    {:reply, result, state}
  end

  def handle_call(:get_high_threshold, _from, state) do
    result = Comm.read_high_threshold(state.transport)

    {:reply, result, state}
  end

  def handle_call({:set_high_threshold, value}, _from, state) do
    result = Comm.write_high_threshold(state.transport, value)

    {:reply, result, state}
  end

  def handle_call(:get_power_saving, _from, state) do
    result = Comm.read_power_saving(state.transport)

    {:reply, result, state}
  end

  def handle_call({:set_power_saving, mode, enable}, _from, state) do
    result = Comm.write_power_saving(state.transport, mode, enable)

    {:reply, result, state}
  end

  def handle_call(:get_interrupt_status, _from, state) do
    result = Comm.read_interrupt_status(state.transport)

    {:reply, result, state}
  end

  @impl GenServer
  def handle_info(:perform_measurement, state) do
    new_state =
      case Comm.read_als_output(state.transport, state.resolution) do
        {:ok, new_measurement} ->
          %{state | last_measurement: new_measurement}

        _ ->
          state
      end

    {:noreply, new_state, {:continue, :schedule_next_run}}
  end

  defp update_state_after_config_change(state, {setting_names, resolution})
       when is_list(setting_names) and is_number(resolution) do
    Logger.info(
      "VEML7700: configured #{inspect(setting_names)}, resolution: #{inspect(resolution)}"
    )

    %{state | resolution: resolution}
  end
end
