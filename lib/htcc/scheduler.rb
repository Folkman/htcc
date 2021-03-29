# frozen_string_literal: true

module HTCC
  class Scheduler
    attr_reader :device_id

    def initialize(device_id, client)
      @device_id = device_id
      @client = client
    end

    def get_schedule
      resp = @client.send(:request, "/Device/Menu/GetScheduleData/#{device_id}", method: 'post')
      @schedule = JSON.parse(resp.body)
    end
  end
end

# TODO:

# EDIT_SCHEDULE_PATH = '/Device/Menu/EditSchedule/' + device_id
# CONFIRM_SCHEDULE_PATH = '/Device/Menu/SendSchedule?deviceId=' + device_id
# DISCARD_SCHEDULE_PATH = '/Device/Menu/DiscardChangesInSchedule?deviceID=' + device_id

# FormData Encoded:

# DeviceID: 123456
# Days[0]: True
# Days[1]: True
# Days[2]: True
# Days[3]: True
# Days[4]: True
# Days[5]: True
# Days[6]: True
# DayChange: True
# Templates[0].Editable: True
# Templates[0].OrigIsCancelled: false
# Templates[0].Editable: True
# Templates[0].Type: WakeOcc1
# Templates[0].OrigStartTime: 05:45:00
# Templates[0].OrigFanMode: Auto
# Templates[0].OrigHeatSetpoint: 68
# Templates[0].OrigCoolSetpoint: 79
# Templates[0].StartTime: 05:45:00
# Templates[0].IsCancelled: false
# Templates[1].Editable: True
# Templates[1].OrigIsCancelled: true
# Templates[1].Editable: True
# Templates[1].Type: LeaveUnocc1
# Templates[1].OrigStartTime: 08:00:00
# Templates[1].OrigFanMode: Auto
# Templates[1].OrigHeatSetpoint: 62
# Templates[1].OrigCoolSetpoint: 85
# Templates[1].StartTime: 08:00:00
# Templates[1].IsCancelled: true
# Templates[2].Editable: True
# Templates[2].OrigIsCancelled: true
# Templates[2].Editable: True
# Templates[2].Type: ReturnOcc2
# Templates[2].OrigStartTime: 18:00:00
# Templates[2].OrigFanMode: Auto
# Templates[2].OrigHeatSetpoint: 70
# Templates[2].OrigCoolSetpoint: 78
# Templates[2].StartTime: 18:00:00
# Templates[2].IsCancelled: true
# Templates[3].Editable: True
# Templates[3].OrigIsCancelled: false
# Templates[3].Editable: True
# Templates[3].Type: SleepUnocc2
# Templates[3].OrigStartTime: 21:30:00
# Templates[3].OrigFanMode: Auto
# Templates[3].OrigHeatSetpoint: 64
# Templates[3].OrigCoolSetpoint: 78
# Templates[3].StartTime: 21:30:00
# Templates[3].IsCancelled: false
# Templates[0].Type: WakeOcc1
# Templates[0].HeatSetpoint: 68
# Templates[0].CoolSetpoint: 79
# Templates[1].Type: LeaveUnocc1
# Templates[1].HeatSetpoint: 62
# Templates[1].CoolSetpoint: 85
# Templates[2].Type: ReturnOcc2
# Templates[2].HeatSetpoint: 70
# Templates[2].CoolSetpoint: 78
# Templates[3].Type: SleepUnocc2
# Templates[3].HeatSetpoint: 64
# Templates[3].CoolSetpoint: 78
# DisplayUnits: Fahrenheit
# IsCommercial: False
# ScheduleFan: True
# Templates[0].FanMode: Auto
# Templates[1].FanMode: Auto
# Templates[2].FanMode: Auto
# Templates[3].FanMode: Auto
# ScheduleOtherDays: False
