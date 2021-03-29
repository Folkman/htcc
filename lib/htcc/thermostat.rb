# frozen_string_literal: true

module HTCC
  class Thermostat
    SYSTEM_MODES = %i[emergency_heat heat off cool auto]
    FAN_MODES = %i[auto on circulate schedule]
    HOLD_TYPES = %i[none temporary permanent]
    EQUIPMENT_OUTPUT_STATUS = %i[off heating cooling fan_running]

    attr_reader :info

    def initialize(info, client)
      @info = info
      @client = client
      @refresh = true
      @status = {}
    end

    def Scheduler
      @scheduler ||= Scheduler.new(id, @client)
    end

    def Settings
      @settings ||= Settings.new(id, @client)
    end

    def id
      @info['DeviceID']
    end

    def mac_address
      @info['MacID']
    end

    def name
      @info['Name']
    end

    def connected?
      get_status
      @status['deviceLive'] && !@status['communicationLost']
    end

    def status(refresh = false)
      get_status if @status.empty? || refresh
      @status
    end

    def system_mode
      get_status
      SYSTEM_MODES[@status['latestData']['uiData']['SystemSwitchPosition']]
    end

    def system_mode=(mode)
      unless system_modes.index(mode)
        raise SystemError.new("Unknown mode: #{mode.inspect}. Allowed modes: #{system_modes.inspect}")
      end
      change_setting(system_mode: mode)
    end

    def has_fan?
      return @has_fan unless @has_fan.nil?

      get_status if @status.empty?
      @has_fan = @status['latestData']['hasFan']
    end

    def fan_running?
      get_status
      @status['latestData']['fanData']['fanIsRunning']
    end

    def fan_mode
      get_status
      FAN_MODES[@status['latestData']['fanData']['fanMode']]
    end

    def fan_mode=(mode)
      unless fan_modes.index(mode)
        raise FanError.new("Unknown mode: #{mode.inspect}. Allowed modes: #{fan_modes.inspect}")
      end
      change_setting(fan_mode: mode)
    end

    # Current ambient temperature
    def current_temperature
      get_status
      @status['latestData']['uiData']['DispTemperature']
    end

    def temperature_unit
      get_status
      @status['latestData']['uiData']['DisplayUnits']
    end

    # Cooling temperature setting
    def cool_setpoint
      get_status
      @status['latestData']['uiData']['CoolSetpoint']
    end

    def cool_setpoint=(temp)
      raise_min_setpoint(min_cool_setpoint, temp) if temp < min_cool_setpoint
      raise_max_setpoint(max_cool_setpoint, temp) if temp > max_cool_setpoint
      change_setting(cool_setpoint: temp, hold: :temporary)
    end

    # Heating temperature setting
    def heat_setpoint
      get_status
      @status['latestData']['uiData']['HeatSetpoint']
    end

    def heat_setpoint=(temp)
      raise_min_setpoint(min_heat_setpoint, temp) if temp < min_heat_setpoint
      raise_max_setpoint(max_heat_setpoint, temp) if temp > max_heat_setpoint
      change_setting(heat_setpoint: temp, hold: :temporary)
    end

    def resume_schedule
      change_setting(hold: :none)
    end

    def hold
      get_status
      HOLD_TYPES[@status['latestData']['uiData']['StatusHeat']] # Both status are the same
    end

    def hold=(mode)
      unless HOLD_TYPES.index(mode)
        raise HoldError.new("Unknown mode: #{mode.inspect}. Allowed modes: #{HOLD_TYPES.inspect}")
      end
      change_setting(hold: mode)
    end

    def output_status
      get_status
      status = @status['latestData']['uiData']['EquipmentOutputStatus']
      status = no_refresh { fan_running? ? 3 : status } if status.zero?
      EQUIPMENT_OUTPUT_STATUS[@status['latestData']['uiData']['EquipmentOutputStatus']]
    end

    def system_modes
      return @system_modes if @system_modes

      get_status if @status.empty?
      allowed_modes = [
        @status['latestData']['uiData']['SwitchEmergencyHeatAllowed'],
        @status['latestData']['uiData']['SwitchHeatAllowed'],
        @status['latestData']['uiData']['SwitchOffAllowed'],
        @status['latestData']['uiData']['SwitchCoolAllowed'],
        @status['latestData']['uiData']['SwitchAutoAllowed'],
      ]
      @system_modes = SYSTEM_MODES.select.with_index { |_, i| allowed_modes[i] }
    end

    def fan_modes
      return @fan_modes if @fan_modes

      get_status if @status.empty?
      allowed_modes = [
        @status['latestData']['fanData']['fanModeAutoAllowed'],
        @status['latestData']['fanData']['fanModeOnAllowed'],
        @status['latestData']['fanData']['fanModeCirculateAllowed'],
        @status['latestData']['fanData']['fanModeFollowScheduleAllowed']
      ]
      @fan_modes = FAN_MODES.select.with_index { |_, i| allowed_modes[i] }
    end

    def no_refresh(&block)
      @refresh = false
      result = yield
      @refresh = true
      result
    end

    private

    def get_status
      return @status if @status && !@refresh

      resp = @client.send(:request, "/Device/CheckDataSession/#{id}?_=#{Time.now.to_i}")
      @status = JSON.parse(resp.body)
    end

    # Required separation between high and low setpoints
    def deadband
      return @deadband if @deadband

      get_status if @status.empty?
      @deadband = @status['latestData']['uiData']['Deadband']
    end

    def min_cool_setpoint
      @info['ThermostatData']['MinCoolSetpoint']
    end

    def max_cool_setpoint
      @info['ThermostatData']['MaxCoolSetpoint']
    end

    def min_heat_setpoint
      @info['ThermostatData']['MinHeatSetpoint']
    end

    def max_heat_setpoint
      @info['ThermostatData']['MaxHeatSetpoint']
    end

    def raise_min_setpoint(min_temp, given_temp)
      raise TemperatureError.new("Minimum setpoint is #{min_temp}. Given: #{given_temp}")
    end

    def raise_max_setpoint(max_temp, given_temp)
      raise TemperatureError.new("Maximum setpoint is #{max_temp}. Given: #{given_temp}")
    end

    def payload(
      system_mode: nil,
      heat_setpoint: nil,
      cool_setpoint: nil,
      heat_next_period: nil,
      cool_next_period: nil,
      hold: nil,
      fan_mode: nil
    )
      {
        'DeviceID':       id,
        'SystemSwitch':   SYSTEM_MODES.index(system_mode),
        'HeatSetpoint':   heat_setpoint,  
        'CoolSetpoint':   cool_setpoint,
        'HeatNextPeriod': heat_next_period, # 0 = hold until 00:00, ..., 92 = hold until 23:45
        'CoolNextPeriod': cool_next_period, # 0 = hold until 00:00, ..., 92 = hold until 23:45
        'StatusHeat':     HOLD_TYPES.index(hold),
        'StatusCool':     HOLD_TYPES.index(hold),
        'FanMode':        FAN_MODES.index(fan_mode)
      }
    end

    def change_setting(**data)
      resp = @client.send(:request, '/Device/SubmitControlScreenChanges',
        method: 'post',
        data: payload(**data)
      )
      JSON.parse(resp.body)['success'] == 1
    end

    class FanError < StandardError; end
    class HoldError < StandardError; end
    class SystemError < StandardError; end
    class TemperatureError < StandardError; end
  end
end
