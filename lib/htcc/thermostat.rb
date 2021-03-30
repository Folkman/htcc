# frozen_string_literal: true

module HTCC
  class Thermostat
    SYSTEM_MODES = %i[emergency_heat heat off cool auto].freeze
    FAN_MODES = %i[auto on circulate schedule].freeze
    HOLD_TYPES = %i[none temporary permanent].freeze
    EQUIPMENT_OUTPUT_STATUS = %i[off heating cooling fan_running].freeze
    HOLD_TIMES = [
      '00:00', '00:15', '00:30', '00:45',
      '01:00', '01:15', '01:30', '01:45',
      '02:00', '02:15', '02:30', '02:45',
      '03:00', '03:15', '03:30', '03:45',
      '04:00', '04:15', '04:30', '04:45',
      '05:00', '05:15', '05:30', '05:45',
      '06:00', '06:15', '06:30', '06:45',
      '07:00', '07:15', '07:30', '07:45',
      '08:00', '08:15', '08:30', '08:45',
      '09:00', '09:15', '09:30', '09:45',
      '10:00', '10:15', '10:30', '10:45',
      '11:00', '11:15', '11:30', '11:45',
      '12:00', '12:15', '12:30', '12:45',
      '13:00', '13:15', '13:30', '13:45',
      '14:00', '14:15', '14:30', '14:45',
      '15:00', '15:15', '15:30', '15:45',
      '16:00', '16:15', '16:30', '16:45',
      '17:00', '17:15', '17:30', '17:45',
      '18:00', '18:15', '18:30', '18:45',
      '19:00', '19:15', '19:30', '19:45',
      '20:00', '20:15', '20:30', '20:45',
      '21:00', '21:15', '21:30', '21:45',
      '22:00', '22:15', '22:30', '22:45',
      '23:00', '23:15', '23:30', '23:45'
    ].freeze

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

    def cool_setpoint_range
      (min_cool_setpoint..max_cool_setpoint)
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

    def heat_setpoint_range
      (min_heat_setpoint..max_heat_setpoint)
    end

    def resume_schedule
      change_setting(hold: :none)
    end

    def hold
      get_status
      HOLD_TYPES[@status['latestData']['uiData']['StatusHeat']] # Both statuses return the same value
    end

    def hold=(mode)
      unless HOLD_TYPES.index(mode)
        raise HoldError.new("Unknown mode: #{mode.inspect}. Allowed modes: #{HOLD_TYPES.inspect}")
      end
      change_setting(hold: mode)
    end

    def hold_until
      get_status
      HOLD_TIMES[@status['latestData']['uiData']['HeatNextPeriod']] # Both periods return the same value
    end

    def hold_until=(time)
      unless HOLD_TIMES.index(time)
        raise HoldError.new(
          "Unknown hold time: #{time.inspect}. Valid times are from 00:00 - 23:45 in 15 minute intervals."
        )
      end
      change_setting(hold_until: time, hold: :temporary)
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
      return @status unless @refresh || @status.empty?

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
      hold_until: nil,
      hold: nil,
      fan_mode: nil
    )
      {
        'DeviceID':       id,
        'SystemSwitch':   SYSTEM_MODES.index(system_mode),
        'HeatSetpoint':   heat_setpoint,  
        'CoolSetpoint':   cool_setpoint,
        'HeatNextPeriod': HOLD_TIMES.index(hold_until),
        'CoolNextPeriod': HOLD_TIMES.index(hold_until),
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
