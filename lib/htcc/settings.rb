# frozen_string_literal: true

module HTCC
  class Settings
    attr_reader :device_id

    def initialize(device_id, client)
      @device_id = device_id
      @client = client
    end

    def update(payload)
      resp = @client.send(:request, '/Device/Menu/Settings', method: 'post', data: payload)
      JSON.parse(resp.body)
    end
  end
end

# TODO:

# Payload that can be posted to '/Device/Menu/Settings'
# {
#   "Name":"THERMOSTAT",
#   "ApplySettingsToAllZones":false,
#   "DeviceID":123456,
#   "DisplayUnits":1,
#   "TempHigherThanActive":true,
#   "TempHigherThan":85,
#   "TempHigherThanMinutes":15,
#   "TempLowerThanActive":true,
#   "TempLowerThan":55,
#   "TempLowerThanMinutes":15,
#   "HumidityHigherThanActive":null,
#   "HumidityHigherThan":null,
#   "HumidityHigherThanMinutes":null,
#   "HumidityLowerThanActive":null,
#   "HumidityLowerThan":null,
#   "HumidityLowerThanMinutes":null,
#   "FaultConditionExistsActive":false,
#   "FaultConditionExistsHours":1,
#   "NormalConditionsActive":true,
#   "ThermostatAlertActive":null,
#   "CommunicationFailureActive":true,
#   "CommunicationFailureMinutes":15,
#   "CommunicationLostActive":true,
#   "CommunicationLostHours":1,
#   "DeviceLostActive":null,
#   "DeviceLostHours":null,
#   "TempHigherThanValue":"85°",
#   "TempLowerThanValue":"55°",
#   "HumidityHigherThanValue":"--%",
#   "HumidityLowerThanValue":"--%",
#   "TempHigherThanMinutesText":"For 15 Minutes",
#   "TempLowerThanMinutesText":"For 15 Minutes",
#   "HumidityHigherThanMinutesText":"For 0 Minutes",
#   "HumidityLowerThanMinutesText":"For 0 Minutes",
#   "FaultConditionExistsHoursText":"Every 1 Hour",
#   "CommunicationFailureMinutesText":"For 15 Minutes",
#   "CommunicationLostHoursText":"After 1 Hour",
#   "DeviceLostHoursText":"After 1 Hour"
# }
