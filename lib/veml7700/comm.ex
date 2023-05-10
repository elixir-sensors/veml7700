defmodule VEML7700.Comm do
  @moduledoc false

  alias VEML7700.Measurement
  alias VEML7700.Register
  alias VEML7700.Transport

  # Initializes the I2C communication to the VEML7700 sensor
  @spec init_transport(binary, Transport.address(), keyword) ::
          {:error, any} | {:ok, Transport.t()}
  def init_transport(bus_name, address, options \\ []) do
    Transport.open(bus_name, address, options)
  end

  ## register 00

  # Configure ALS setting with one or more setting name atoms
  @spec write_als_config(Transport.t(), atom | [atom]) ::
          {:error, any} | {:ok, {setting_names :: [atom], resolution :: float}}
  def write_als_config(transport, als_setting_names) do
    case read_register(transport, :als_config) do
      {:ok, current_value} ->
        new_value =
          current_value
          |> Register.Configuration.from_integer()
          |> Register.Configuration.set(als_setting_names)
          |> Register.Configuration.to_integer()

        case write_register(transport, :als_config, new_value) do
          :ok ->
            read_als_config(transport)

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # Get current ALS settings as setting name atoms and resolution
  @spec read_als_config(Transport.t()) ::
          {:error, any} | {:ok, {setting_names :: [atom], resolution :: float}}
  def read_als_config(transport) do
    case read_register(transport, :als_config) do
      {:ok, uint16} ->
        config = Register.Configuration.from_integer(uint16)
        setting_names = Register.Configuration.to_list(config)
        resolution = Register.Configuration.resolution(config)

        {:ok, {setting_names, resolution}}

      {:error, error} ->
        {:error, error}
    end
  end

  ## register 01

  @spec write_high_threshold(Transport.t(), 0..0xFFFF) :: {:error, any} | :ok
  def write_high_threshold(transport, value) do
    write_register(transport, :als_threshold_high, value)
  end

  @spec read_high_threshold(Transport.t()) :: {:error, any} | {:ok, 0..0xFFFF}
  def read_high_threshold(transport) do
    read_register(transport, :als_threshold_high)
  end

  ## register 02

  @spec write_low_threshold(Transport.t(), 0..0xFFFF) :: {:error, any} | :ok
  def write_low_threshold(transport, value) do
    write_register(transport, :als_threshold_low, value)
  end

  @spec read_low_threshold(Transport.t()) :: {:error, any} | {:ok, 0..0xFFFF}
  def read_low_threshold(transport) do
    read_register(transport, :als_threshold_low)
  end

  ## register 03

  @spec write_power_saving(Transport.t(), 0..3, boolean) :: {:error, any} | :ok
  def write_power_saving(transport, mode, enable) do
    case read_register(transport, :als_power_saving) do
      {:ok, current_value} ->
        new_value =
          current_value
          |> Register.PowerSaving.from_integer()
          |> Register.PowerSaving.set_enabled(enable)
          |> Register.PowerSaving.set_mode(mode)
          |> Register.PowerSaving.to_integer()

        write_register(transport, :als_power_saving, new_value)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec read_power_saving(Transport.t()) ::
          {:error, any} | {:ok, {mode :: 0..3, enabled :: boolean}}
  def read_power_saving(transport) do
    case read_register(transport, :als_power_saving) do
      {:ok, current_value} ->
        {mode, enabled} =
          current_value
          |> Register.PowerSaving.from_integer()
          |> Register.PowerSaving.to_tuple()

        {:ok, {mode, enabled}}

      {:error, error} ->
        {:error, error}
    end
  end

  ## register 04

  @spec read_als_output(Transport.t(), number) :: {:error, any} | {:ok, Measurement.t()}
  def read_als_output(transport, resolution) do
    case read_register(transport, :als_output) do
      {:ok, new_value} ->
        {:ok, Measurement.new(new_value, resolution)}

      {:error, error} ->
        {:error, error}
    end
  end

  ## register 06

  @spec read_interrupt_status(Transport.t()) ::
          {:error, any} | {:ok, [:high_threshold_crossed | :low_threshold_crossed]}
  def read_interrupt_status(transport) do
    case read_register(transport, :interrupt_status) do
      {:ok, new_value} ->
        {:ok, Register.InterruptStatus.from_integer(new_value)}

      {:error, error} ->
        {:error, error}
    end
  end

  ## generic read and write

  # Write value with command name
  @spec write_register(Transport.t(), atom, 0..0xFFFF) :: {:error, any} | :ok
  def write_register(transport, cmd, value) when is_atom(cmd) do
    write_register(transport, Register.command_register(cmd), value)
  end

  # Writes 16-bit value using command 0, 1, 2 or 3
  @spec write_register(Transport.t(), 0..6, 0..0xFFFF) :: {:error, any} | :ok
  def write_register(%Transport{} = transport, cmd, value) when is_integer(cmd) do
    Transport.write(transport, <<cmd, value::little-16>>)
  end

  # Read value with command name
  @spec read_register(Transport.t(), atom) :: {:error, any} | {:ok, 0..0xFFFF}
  def read_register(transport, cmd) when is_atom(cmd) do
    read_register(transport, Register.command_register(cmd))
  end

  # Reads 16-bit value using command 4, 5 or 6
  @spec read_register(Transport.t(), 0..6) :: {:error, any} | {:ok, 0..0xFFFF}
  def read_register(%Transport{} = transport, cmd) when is_integer(cmd) do
    case Transport.write_read(transport, <<cmd>>, 2) do
      {:ok, <<value::little-16>>} ->
        {:ok, value}

      {:error, error} ->
        {:error, error}
    end
  end
end
