defmodule VEML7700 do
  @moduledoc """
  Use Vishay VEML7700 ambient light sensors in Elixir
  """

  use GenServer
  alias VEML7700.Comm
  alias VEML7700.Measurement
  alias VEML7700.Transport
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
          | {:bus_address, Transport.address()}
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

  @spec get_als_config(GenServer.server()) :: {:error, any} | {:ok, map}
  def get_als_config(server \\ __MODULE__) do
    GenServer.call(server, :get_als_config)
  end

  @spec set_als_config(GenServer.server(), als_gain | als_integration_time) :: {:error, any} | :ok
  def set_als_config(server \\ __MODULE__, als_setting_names) do
    GenServer.call(server, {:set_als_config, als_setting_names})
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
